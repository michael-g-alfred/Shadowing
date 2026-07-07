import SwiftUI

struct ExecutorView: View {
    
    @Environment(DIContainer.self) private var container
    @State private var vm: ExecutorViewModel
    
    init(vm: ExecutorViewModel) {
        _vm = State(initialValue: vm)
    }
    
    var body: some View {
        VStack(spacing: 16) {
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
            .padding(.horizontal)
            
            Group {
                switch vm.selectedTab {
                    case .allTasks:
                        container.makeExecutorAllTasksView()
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
        .sheet(isPresented: $vm.showAppliedSheet) {
            AppliedSheet(vm: vm)
                .presentationDetents([.fraction(0.75)])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $vm.showRateRequesterSheet) {
            if let taskId = vm.selectedTaskIdForRating {
                container.makeRatingSheet(taskId: taskId, target: .requester)
                    .presentationDetents([.fraction(0.75)])
                    .presentationDragIndicator(.visible)
            }
        }
    }
}
