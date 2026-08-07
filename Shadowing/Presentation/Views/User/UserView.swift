import SwiftUI

struct UserView: View {
    
        // MARK: - Environment
    @Environment(DIContainer.self) private var container
    @Environment(\.colorScheme) private var colorScheme
    
        // MARK: - Properties
    private var listRowColor: Color? {
        colorScheme == .dark
        ? Color.accentColor.opacity(0.15)
        : nil
    }
    
    private var listErrorRowColor: Color? {
        colorScheme == .dark
        ? Color.orange.opacity(0.15)
        : nil
    }
    
        // MARK: - State
    @State private var vm: UserViewModel
    
        // MARK: - Init
    init(userId: String, vm: UserViewModel) {
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
                        userContent(for: user)
                    } else {
                        EmptyState.noProfile.view {
                            await vm.loadUser()
                        }
                    }
                }
            }
            .task {
                await vm.loadUser()
            }
            .sheet(isPresented: Bindable(vm).isRatingsPresented) {
                if let user = vm.user {
                    container.makeRatingsView(userId: user.id, userName: user.displayName)
                        .appSheetStyle()
                }
            }
        }
    }
    
        // MARK: - Private Views
    private func userContent(for user: UserSummaryModel) -> some View {
        List {
            Section {
                AvatarView(profile: user, size: 100, nameLayout: .vertical, nameFont: .title2, subtitle: user.email)
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                    .listRowInsets(.all, 0)
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
                .listRowBackground(listErrorRowColor)
            }

            if let bio = user.bio, !bio.isEmpty {
                Section("About") {
                    Text(bio).bold()
                        .font(.subheadline)
                }
                .listRowBackground(listRowColor)
            }

            if !user.specialties.isEmpty {
                Section("Specialties") {
                    specialtiesFlow(user.specialties)
                }
                .listRowBackground(listRowColor)
            }
            
            Section("Stats") {
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
            }
            .listRowBackground(listRowColor)
        }
        .scrollContentBackground(.hidden)
    }

    private func specialtiesFlow(_ specialties: [SpecialtyModel]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                ForEach(specialties) { specialty in
                    Label(specialty.label, systemImage: specialty.icon)
                        .font(.footnote).bold()
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .appGlassCapsule(
                            overlayColor: .green.opacity(0.1),
                            strokeColor: .green.opacity(0.05),
                            shadowColor: .green.opacity(0.05)
                        )
                }
            }
        }
    }
}
