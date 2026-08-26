import SwiftUI

    // MARK: - Container

struct ExecutorView: View {
    
        // MARK: Environment
    @Environment(DIContainer.self) private var container
    
        // MARK: State
    @State private var vm: ExecutorViewModel
    
        // MARK: Init
    init(vm: ExecutorViewModel) {
        _vm = State(initialValue: vm)
    }
    
        // MARK: Body
    var body: some View {
        VStack(spacing: Spacing.lg) {
            ExecutorTabHeader(vm: vm)
            ExecutorTabContent(container: container, selectedTab: vm.selectedTab)
        }
        .toolbar {
            ExecutorToolbar(vm: vm)
        }
    }
}

    // MARK: - Header (picker + favorites toggle)

private struct ExecutorTabHeader: View {
    let vm: ExecutorViewModel
    
    var body: some View {
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
                .accessibilityLabel("Show favorites only")
            }
        }
        .padding(.horizontal)
        .padding(.top, Spacing.sm)
    }
}

    // MARK: - Content

private struct ExecutorTabContent: View {
    let container: DIContainer
    let selectedTab: ExecutorTab
    
    var body: some View {
        Group {
            switch selectedTab {
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
}

    // MARK: - Toolbar

private struct ExecutorToolbar: ToolbarContent {
    @Bindable var vm: ExecutorViewModel
    
    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            if vm.selectedTab == .availableTasks {
                Button {
                    vm.isSearchPresented.toggle()
                } label: {
                    Image(systemName: "magnifyingglass")
                }
            }
        }
    }
}
