import SwiftUI

    // MARK: - Container

struct UserView: View {
    
        // MARK: Environment
    @Environment(DIContainer.self) private var container
    
        // MARK: State
    @State private var vm: UserViewModel
    
        // MARK: Init
    init(vm: UserViewModel) {
        self.vm = vm
    }
    
        // MARK: Body
    var body: some View {
        ScreenContainer {
            UserContentView(state: state(for: vm), vm: vm)
        }
        .ratingsSheet(
            userId: vm.user?.id,
            userName: vm.user?.displayName,
            isPresented: Bindable(vm).isRatingsPresented
        )
        .task {
            await vm.loadUser()
        }
    }
    
        // MARK: Private Helpers
    private func state(for vm: UserViewModel) -> ViewState<UserSummaryModel> {
        if vm.isLoading && vm.user == nil { return .loading }
        guard let user = vm.user else { return .empty }
        return .loaded(user)
    }
}

    // MARK: - Content (state routing)

private struct UserContentView: View {
    let state: ViewState<UserSummaryModel>
    let vm: UserViewModel
    
    var body: some View {
        DataStateView(
            state: state,
            loadingState: .loading(title: "Loading user"),
            emptyState: .noProfile,
            retryAction: { await vm.loadUser() }
        ) { user in
            UserLoadedView(user: user, vm: vm)
        }
    }
}

    // MARK: - Loaded

private struct UserLoadedView: View {
    
        // MARK: Environment
    @Environment(\.colorScheme) private var colorScheme
    
        // MARK: Properties
    let user: UserSummaryModel
    let vm: UserViewModel
    
    private var listRowColor: Color? {
        colorScheme == .dark ? Color.accentColor.opacity(0.15) : nil
    }
    
    private var listErrorRowColor: Color? {
        colorScheme == .dark ? Color.orange.opacity(0.15) : nil
    }
    
        // MARK: Body
    var body: some View {
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
                Section {
                    Text(bio).bold()
                } header: {
                    Label("About", systemImage: "person.text.rectangle")
                }
                .listRowBackground(listRowColor)
            }
            
            if !user.specialties.isEmpty {
                Section {
                    SpecialtiesFlow(specialties: user.specialties)
                } header: {
                    Label("Specialties", systemImage: "medal.star")
                }
                .listRowBackground(listRowColor)
            }
            
            Section {
                InfoRow(
                    title: "Completed Tasks",
                    systemImage: "checklist",
                    localizedValue: "\(user.completedTasks)"
                )
                
                InfoRow(
                    title: "Total Ratings",
                    systemImage: "list.star",
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
            } header: {
                Label("Stats", systemImage: "chart.line.uptrend.xyaxis")
            }
            .listRowBackground(listRowColor)
        }
        .scrollContentBackground(.hidden)
    }
}
