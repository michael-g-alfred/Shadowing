import SwiftUI

struct RequesterView: View {
    
    // MARK: - Environment
    @Environment(DIContainer.self) private var container
    
    // MARK: - State
    @State private var vm: RequesterViewModel
    
    // MARK: - Init
    init(vm: RequesterViewModel) {
        _vm = State(initialValue: vm)
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 16) {
            Picker(
                "Tasks",
                selection: Binding(
                    get: { vm.selectedTab },
                    set: { vm.select($0) }
                )
            ) {
                ForEach(RequesterTab.allCases, id: \.self) { tab in
                    Text(tab.tabName)
                        .tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 8)
            
            Group {
                switch vm.selectedTab {
                    case .publishedTasks:
                        container.makeRequesterPublishedTasksView()
                    case .completedTasks:
                        container.makeRequesterCompletedTasksView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Show Add Task Sheet", systemImage: "plus") {
                    vm.showAddTaskSheet.toggle()
                }
                .buttonStyle(.glassProminent)
            }
        }
        .sheet(isPresented: $vm.showAddTaskSheet) {
            container.makeAddTaskSheet()
        }
        .sheet(isPresented: $vm.showApplicantsSheet) {
            container.makeApplicantsSheet()
                .presentationDetents([.fraction(0.75)])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $vm.showRateExecutorSheet) {
            if let taskId = vm.selectedTaskIdForRating, let name = vm.executorName {
                container.makeRatingSheet(taskId: taskId, target: .executor(displayName: name))
                    .presentationDetents([.fraction(0.75)])
                    .presentationDragIndicator(.visible)
            }
        }
    }
}
