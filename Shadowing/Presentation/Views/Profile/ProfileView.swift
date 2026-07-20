import SwiftUI
import PhotosUI

struct ProfileView: View {
    
        // MARK: - Environment
    @Environment(DIContainer.self) private var container
    @Environment(\.openURL) private var openURL
    
        // MARK: - State
    @State private var vm: ProfileViewModel
    @State private var isIdExpanded = false
    @State private var isNationalIDAppearance = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isRatingsPresented = false
    
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
            .navigationTitle("\(vm.user?.displayName ?? "Guest")'s Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        if vm.isUploadingAvatar {
                            ProgressView()
                        } else {
                            Label("Change Photo", systemImage: "camera.fill")
                        }
                    }
                    .disabled(vm.isUploadingAvatar || vm.user == nil)
                }
                
                ToolbarItem(placement: .destructiveAction) {
                    Button(role: .destructive) {
                        Task {
                            await submit()
                        }
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                    .tint(.red)
                    .buttonStyle(.glassProminent)
                }
            }
            .task {
                await vm.loadProfile()
            }
            .refreshable {
                await vm.loadProfile()
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    guard let newItem,
                          let data = try? await newItem.loadTransferable(type: Data.self) else { return }
                    await vm.uploadAvatar(imageData: data)
                }
            }
            .sheet(isPresented: $isRatingsPresented) {
                if let user = vm.user {
                        container.makeRatingsView(userId: user.id, userName: user.displayName)
                            .presentationDetents([.fraction(0.75)])
                            .presentationDragIndicator(.visible)
                }
            }
        }
    }
    
        // MARK: - Private Views
    private func profileContent(for user: UserModel) -> some View {
        List {
            Section {
                AvatarView(profile: user, size: 90, nameLayout: .vertical, nameFont: .title2)
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                    .listRowInsets(.all, 0)
                    .padding(.vertical, 8)
            }
            
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
                    isRatingsPresented = true
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
            
            locationSection
            
            languageSection
        }
    }
    
    private var locationSection: some View {
        Section("Location Access") {
            Label(vm.locationStatusTitle, systemImage: vm.locationStatusIcon)
                .bold()
                .foregroundStyle(vm.locationStatusTint)
            
            if vm.needsLocationSettingsRedirect {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURL(url)
                    }
                }
            } else if vm.needsLocationRequest {
                Button("Enable Location") {
                    vm.requestLocationAccess()
                }
            }
        }
    }
    
    private var languageSection: some View {
        Section("Language") {
            Picker("App Language", selection: Binding(
                get: { vm.currentLanguage },
                set: { vm.setLanguage($0) }
            )) {
                ForEach(AppLanguage.allCases, id: \.self) { language in
                    Text(language.title).tag(language)
                }
            }
            .pickerStyle(.segmented)
        }
    }
    
    private func nationalIdRow(nationalId: String) -> some View {
        InfoRow(title: "National ID", systemImage: "person.text.rectangle") {
            Text(isNationalIDAppearance ? nationalId : String(repeating: "*", count: 14))
                .bold()
                .contentTransition(.numericText())
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation {
                isNationalIDAppearance.toggle()
            }
        }
    }
    
    private func idRow(for user: UserModel) -> some View {
        InfoRow(title: "Id", systemImage: "person.badge.key") {
            Text(user.id.isEmpty ? "—" : displayedId(for: user.id))
                .font(.caption)
                .contentTransition(.numericText())
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation {
                isIdExpanded.toggle()
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
    
    private func displayedId(for id: String) -> String {
        guard !isIdExpanded else { return id }
        return "\(id.prefix(9))...."
    }
    
        // MARK: - Private Methods
    private func submit() async {
        guard await vm.signout() else { return }
        container.setAppState(.auth)
        container.relaunchRoot()
    }
}
