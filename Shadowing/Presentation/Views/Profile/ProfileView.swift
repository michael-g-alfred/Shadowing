import SwiftUI
import PhotosUI

    // MARK: - Container

struct ProfileView: View {
    
        // MARK: Environment
    @Environment(DIContainer.self) private var container
    
        // MARK: State
    @State private var vm: ProfileViewModel
    
        // MARK: Init
    init(vm: ProfileViewModel) {
        _vm = State(initialValue: vm)
    }
    
        // MARK: Body
    var body: some View {
        NavigationStack {
            ScreenContainer {
                ProfileContentView(state: state, vm: vm, container: container)
            }
            .navigationTitle("\(vm.user?.displayName ?? "Guest")")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ProfileToolbar(vm: vm, onSignOut: { await signOut() })
            }
            .task { await vm.loadProfile() }
            .refreshable { await vm.loadProfile() }
            .confirmationDialog("Change Photo", isPresented: $vm.isPhotoSourceDialogPresented, titleVisibility: .visible) {
                Button("Take Photo") {
                    vm.isCameraPresented = true
                }
                Button("Choose from Library") {
                    vm.isLibraryPickerPresented = true
                }
                Button("Choose File") {
                    vm.isFilePickerPresented = true
                }
                Button("Cancel", role: .cancel) {}
            }
            .photosPicker(
                isPresented: Bindable(vm).isLibraryPickerPresented,
                selection: Bindable(vm).selectedPhotoItem,
                matching: .images
            )
            .fullScreenCover(isPresented: Bindable(vm).isCameraPresented) {
                CameraPicker { data in
                    vm.handleCameraCapture(data)
                }
                .ignoresSafeArea()
            }
            .sheet(isPresented: Bindable(vm).isFilePickerPresented) {
                FilePicker(
                    onFilePicked: { data in vm.handleFilePicked(data) },
                    onError: { message in vm.handleFilePickerError(message) }
                )
            }
            .sheet(isPresented: Bindable(vm).isRatingsPresented) {
                if let user = vm.user {
                    container.makeRatingsView(userId: user.id, userName: user.displayName)
                        .appSheetStyle()
                }
            }
            .sheet(isPresented: Bindable(vm).isSettingsPresented) {
                container.makeSettingsView()
                    .appSheetStyle()
            }
        }
    }
    
        // MARK: Private Helpers
    private var state: ViewState<UserModel> {
        if vm.isLoading && vm.user == nil { return .loading }
        guard let user = vm.user else { return .empty }
        return .loaded(user)
    }
    
    private func signOut() async {
        guard await vm.signout() else { return }
        container.setAppState(.auth)
        container.relaunchRoot()
    }
}

    // MARK: - Content (state routing)

private struct ProfileContentView: View {
    let state: ViewState<UserModel>
    let vm: ProfileViewModel
    let container: DIContainer
    
    var body: some View {
        DataStateView(
            state: state,
            loadingState: .loading(title: "Loading profile", subtitle: "Please wait a moment..."),
            emptyState: .noProfile,
            retryAction: { await vm.loadProfile() }
        ) { user in
            ProfileLoadedView(user: user, vm: vm, container: container)
        }
    }
}

    // MARK: - Toolbar

private struct ProfileToolbar: ToolbarContent {
    let vm: ProfileViewModel
    let onSignOut: () async -> Void
    
    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                vm.isSettingsPresented = true
            } label: {
                Label("Settings", systemImage: "gearshape.fill")
            }
        }
        
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                vm.isPhotoSourceDialogPresented = true
            } label: {
                if vm.isUploadingAvatar {
                    ProgressView()
                } else {
                    Label("Change Photo", systemImage: "camera.fill")
                }
            }
            .disabled(vm.isUploadingAvatar || vm.user == nil)
        }
        
        ToolbarSpacer(placement: .topBarTrailing)
        
        ToolbarItem(placement: .destructiveAction) {
            Button(role: .destructive) {
                Task { await onSignOut() }
            } label: {
                Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
            }
            .tint(.red)
        }
    }
}

    // MARK: - Loaded

private struct ProfileLoadedView: View {
    
        // MARK: Environment
    @Environment(\.colorScheme) private var colorScheme
    
        // MARK: Properties
    let user: UserModel
    let vm: ProfileViewModel
    let container: DIContainer
    
    private var listRowColor: Color? {
        colorScheme == .dark ? Color.accentColor.opacity(0.15) : nil
    }
    
    private var listErrorRowColor: Color? {
        colorScheme == .dark ? Color.orange.opacity(0.15) : nil
    }
    
        // MARK: Body
    var body: some View {
        let accountStatus = container.lookupStore.accountStatus(named: user.accountStatus)
        let statusLabel = accountStatus?.label ?? user.accountStatus
        let statusColor = accountStatus?.color ?? .gray
        
        List {
            avatarSection
            
            if user.isSuspended {
                suspensionSection(statusLabel: statusLabel, statusColor: statusColor)
            }
            
            if let errorMessage = vm.errorMessage {
                ProfileErrorSection(message: errorMessage, background: listErrorRowColor)
            }
            
            if let bio = user.bio, !bio.isEmpty {
                Section("About") {
                    Text(bio).bold()
                }
                .listRowBackground(listRowColor)
            }
            
            if !user.specialties.isEmpty {
                Section("Specialties") {
                    SpecialtiesFlow(specialties: user.specialties)
                }
                .listRowInsets(.all, 0)
                .listRowBackground(Color.clear)
            }
            
            accountSection(user: user, statusLabel: statusLabel, statusColor: statusColor)
        }
        .scrollContentBackground(.hidden)
    }
    
        // MARK: Sections
    private var avatarSection: some View {
        Section {
            AvatarView(profile: user, size: 100, nameLayout: .vertical, nameFont: .title2)
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
                .listRowInsets(.all, 0)
                .padding(.vertical, Spacing.sm)
        }
        .listRowBackground(Color.clear)
    }
    
    private func suspensionSection(statusLabel: String, statusColor: Color) -> some View {
        Section {
            VStack(alignment: .leading, spacing: 4) {
                Label(statusLabel, systemImage: "exclamationmark.triangle.fill")
                    .font(.subheadline).bold()
                Text("You can't apply to new tasks or post new ones right now.")
                    .font(.footnote)
                if let countdown = vm.suspensionCountdownText {
                    Text(countdown)
                        .font(.footnote).bold()
                }
            }
            .foregroundStyle(statusColor)
        }
    }
    
    private func accountSection(user: UserModel, statusLabel: String, statusColor: Color) -> some View {
        Section("Account") {
            InfoRow(title: "Account Status", systemImage: "checkmark.shield") {
                Text(statusLabel)
                    .bold()
                    .foregroundStyle(statusColor)
            }
            
            InfoRow(
                title: "Email",
                systemImage: "envelope",
                value: user.email.isEmpty ? "—" : user.email
            )
            
            InfoRow(
                title: "Completed Tasks",
                systemImage: "checklist",
                localizedValue: "\(user.completedTasks)"
            )
            
            InfoRow(
                title: "Total Ratings",
                systemImage: "person.2",
                localizedValue: user.totalRatings > 0 ? "\(user.totalRatings)" : "-"
            )
            .contentShape(Rectangle())
            .onTapGesture {
                vm.isRatingsPresented = true
            }
            
            InfoRow(
                title: "Rating",
                systemImage: "star",
                localizedValue: user.totalRatings > 0 ? "\(user.rating, specifier: "%.1f")" : "-"
            )
            
            if let createdAt = user.createdAt {
                InfoRow(
                    title: "Member Since",
                    systemImage: "calendar",
                    value: createdAt.formatted(date: .abbreviated, time: .omitted)
                )
            }
            
            ProfileIdRow(user: user, vm: vm)
        }
        .listRowBackground(listRowColor)
    }
}

    // MARK: - Error Banner

private struct ProfileErrorSection: View {
    let message: String
    let background: Color?
    
    var body: some View {
        Section {
            Text(message)
                .foregroundStyle(.orange)
                .font(.footnote).bold()
        } header: {
            Label("Error Message", systemImage: "exclamationmark.triangle")
        }
        .listRowBackground(background)
    }
}

    // MARK: - Specialties

struct SpecialtiesFlow: View {
    let specialties: [SpecialtyModel]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                ForEach(specialties) { specialty in
                    Label(specialty.label, systemImage: specialty.icon)
                        .font(.footnote).bold()
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .appGlassCapsule(
                            overlayColor: .green.opacity(0.1),
                            strokeColor: .green.opacity(0.05)
                        )
                }
            }
        }
    }
}

    // MARK: - ID Row

private struct ProfileIdRow: View {
    let user: UserModel
    let vm: ProfileViewModel
    
    var body: some View {
        InfoRow(title: "Reference Code", systemImage: "person.badge.key") {
            Text(user.id.isEmpty ? "—" : vm.displayedId(for: user.id))
                .font(.caption2)
                .contentTransition(.numericText())
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation {
                vm.toggleIdExpanded()
            }
        }
        .contextMenu {
            Button {
                UIPasteboard.general.string = user.id
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            } label: {
                Label("Copy Reference Code", systemImage: "doc.on.doc")
            }
        }
    }
}
