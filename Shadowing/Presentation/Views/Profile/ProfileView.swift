import SwiftUI

struct ProfileView: View {
    
    @Environment(DIContainer.self) private var container
    @Environment(\.openURL) private var openURL
    @State private var vm: ProfileViewModel
    @State private var isIdExpanded = false
    @State private var isNationalIDAppearance = false
    
    init(vm: ProfileViewModel) {
        _vm = State(initialValue: vm)
    }
    
    var body: some View {
        NavigationStack {
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
            .navigationTitle("\(vm.user?.displayName ?? "Guest")'s Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
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
        }
    }
    
    private func profileContent(for user: UserModel) -> some View {
        List {
            Section {
                VStack(alignment: .center, spacing: 8) {
                    AvatarView(profile: user, size: 64)
                    Text(user.displayName)
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
                .listRowInsets(.all, 0)
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
                    value: "\(user.completedTasks)"
                )
                
                InfoRow(
                    title: "Total Ratings",
                    systemImage: "person.2",
                    value: user.totalRatings > 0 ? String(user.totalRatings) : "No ratings yet"
                )
                
                InfoRow(
                    title: "Rating",
                    systemImage: "star",
                    value: user.totalRatings > 0 ? String(format: "%.1f", user.rating) : "No ratings yet"
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
            
            if let errorMessage = vm.errorMessage {
                Section {
                    Label(errorMessage, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                        .font(.footnote)
                }
            }
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
    
    private func submit() async {
        guard await vm.submit() else { return }
        container.setAppState(.auth)
        container.relaunchRoot()
    }
}
