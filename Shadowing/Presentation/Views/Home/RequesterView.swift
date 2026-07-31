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
        VStack(spacing: Spacing.lg) {
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
            .padding(.top, Spacing.sm)
            
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
        .task {
            await vm.checkPendingRatings()
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Show Add Task Sheet", systemImage: "plus") {
                    vm.showAddTaskSheet.toggle()
                }
            }
            ToolbarSpacer(placement: .topBarLeading)
            ToolbarItem(placement: .topBarLeading) {
                Group {
                    if vm.selectedTab == .publishedTasks
                        && !vm.requesterPublishedTasks.isEmpty
                        && vm.errorMessage == nil {
                        
                        Menu {
                            ForEach(RequesterStatusFilter.allCases) { filter in
                                Button {
                                    vm.setStatusFilter(filter)
                                } label: {
                                    Label(
                                        filter.title,
                                        systemImage: vm.statusFilter == filter
                                        ? "checkmark.circle.fill"
                                        : "circle"
                                    )
                                }
                            }
                        } label: {
                            Image(
                                systemName: vm.statusFilter == .all
                                ? "line.3.horizontal.decrease"
                                : "line.3.horizontal.decrease.circle.fill"
                            )
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $vm.showAddTaskSheet) {
            container.makeAddTaskSheet()
                .appSheetStyle()
        }
        .sheet(isPresented: $vm.showApplicantsSheet) {
            container.makeApplicantsSheet()
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
