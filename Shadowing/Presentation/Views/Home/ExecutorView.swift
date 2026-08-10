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
        .requireLocation(container.locationService)
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
        .alert("Confirm Task Application", isPresented: $vm.showFeeConfirmationAlert) {
            Button("Cancel", role: .cancel) {
                vm.cancelApply()
            }
            .tint(.red)
            
            Button("Confirm", role: .confirm) {
                Task { await vm.confirmApply() }
            }
        } message: {
            Text(vm.feeConfirmationMessage)
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
                .accessibilityLabel("Show favourites only")
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
