import SwiftUI
import PhotosUI

struct ProfileView: View {
    
        // MARK: - Environment
    @Environment(DIContainer.self) private var container
    @Environment(\.colorScheme) private var colorScheme
    
        // MARK: - Property
    private var listRowColor: Color? {
        colorScheme == .dark
        ? Color.accentColor.opacity(0.15)
        : nil
    }
    
        // MARK: - State
    @State private var vm: ProfileViewModel
    
        // MARK: - Init
    init(vm: ProfileViewModel) {
        _vm = State(initialValue: vm)
    }
    
        // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                Group {
                    if vm.isLoading && vm.user == nil {
                        LoadingState.loading(title: "Loading profile…", subtitle: "Please wait a moment").view
                    } else if let user = vm.user {
                        profileContent(for: user)
                    } else {
                        EmptyState.noProfile.view {
                            await vm.loadProfile()
                        }
                    }
                }
            }
            .navigationTitle("\(vm.user?.displayName ?? "Guest")")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        vm.isSettingsPresented = true
                    } label: {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    PhotosPicker(selection: Bindable(vm).selectedPhotoItem, matching: .images) {
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
                        Task {
                            await submit()
                        }
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                    .tint(.red)
                }
            }
            .task {
                await vm.loadProfile()
            }
            .refreshable {
                await vm.loadProfile()
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
    
        // MARK: - Private Views
    private func profileContent(for user: UserModel) -> some View {
        List {
            Section {
                AvatarView(profile: user, size: 100, nameLayout: .vertical, nameFont: .title2)
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                    .listRowInsets(.all, 0)
                    .padding(.vertical, Spacing.sm)
            }
            .listRowBackground(Color.clear)
            
            if let errorMessage = vm.errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.orange)
                        .font(.footnote).bold()
                } header: {
                    Label("Error Message", systemImage: "exclamationmark.triangle")
                }
            }
            
            Section("Account") {
                InfoRow(
                    title: "Email",
                    systemImage: "envelope",
                    value: user.email.isEmpty ? "—" : user.email
                )
                
                if let nationalId = user.nationalId, !nationalId.isEmpty {
                    nationalIdRow(nationalId: nationalId)
                }
                
                InfoRow(
                    title: "Completed Tasks",
                    systemImage: "checklist",
                    localizedValue: "\(user.completedTasks)"
                )
                
                InfoRow(
                    title: "Total Ratings",
                    systemImage: "person.2",
                    localizedValue: user.totalRatings > 0
                    ? "\(user.totalRatings)"
                    : "No ratings yet"
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    vm.isRatingsPresented = true
                }
                
                InfoRow(
                    title: "Rating",
                    systemImage: "star",
                    localizedValue: user.totalRatings > 0
                    ? "\(user.rating, specifier: "%.1f")"
                    : "No ratings yet"
                )
                
                if let createdAt = user.createdAt {
                    InfoRow(
                        title: "Member Since",
                        systemImage: "calendar",
                        value: createdAt.formatted(date: .abbreviated, time: .omitted)
                    )
                }
                
                idRow(for: user)
            }
            .listRowBackground(listRowColor)
        }
        .scrollContentBackground(.hidden)
    }
    
    private func nationalIdRow(nationalId: String) -> some View {
        InfoRow(title: "National ID", systemImage: "person.text.rectangle") {
            Text(vm.isNationalIDAppearance ? nationalId : String(repeating: "*", count: 14))
                .bold()
                .contentTransition(.numericText())
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation {
                vm.toggleNationalIDAppearance()
            }
        }
    }
    
    private func idRow(for user: UserModel) -> some View {
        InfoRow(title: "Id", systemImage: "person.badge.key") {
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
                Label("Copy ID", systemImage: "doc.on.doc")
            }
        }
    }
    
        // MARK: - Private Methods
    private func submit() async {
        guard await vm.signout() else { return }
        container.setAppState(.auth)
        container.relaunchRoot()
    }
}
