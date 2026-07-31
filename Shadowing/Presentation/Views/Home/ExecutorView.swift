import SwiftUI

struct ExecutorView: View {
    
        // MARK: - Environment
    @Environment(DIContainer.self) private var container
    
        // MARK: - State
    @State private var vm: ExecutorViewModel
    
        // MARK: - Init
    init(vm: ExecutorViewModel) {
        _vm = State(initialValue: vm)
    }
    
        // MARK: - Body
    var body: some View {
        VStack(spacing: Spacing.lg) {
            HStack(spacing: Spacing.sm) {
                Picker(
                    "Tasks",
                    selection: Binding(
                        get: { vm.selectedTab },
                        set: { vm.select($0) }
                    )
                ) {
                    ForEach(ExecutorTab.allCases, id: \.self) { tab in
                        Text(tab.tabName)
                            .tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                
                if vm.selectedTab == .availableTasks {
                    Button {
                        vm.showFavoritesOnly.toggle()
                    } label: {
                        Image(systemName: vm.showFavoritesOnly ? "star.fill" : "star")
                            .foregroundStyle(vm.showFavoritesOnly ? .rating : .secondary)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityLabel("Show favourites only")
                }
            }
            .padding(.horizontal)
            .padding(.top, Spacing.sm)
            
            Group {
                switch vm.selectedTab {
                    case .availableTasks:
                        container.makeExecutorAvailableTasksView()
                    case .assignedTasks:
                        container.makeExecutorAssignedTasksView()
                    case .completedTasks:
                        container.makeExecutorCompletedTasksView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .task {
            await vm.checkPendingRatings()
        }
        .sheet(isPresented: $vm.showAppliedSheet) {
            AppliedSheet(vm: vm)
                .appSheetStyle()
        }
        .sheet(isPresented: Binding(
            get: { vm.selectedChatTaskId != nil },
            set: { if !$0 { vm.selectedChatTaskId = nil } }
        )) {
            if let taskId = vm.selectedChatTaskId {
                container.makeDirectChatDetailView(taskId: taskId)
                    .appSheetStyle()
            }
        }
    }
}
