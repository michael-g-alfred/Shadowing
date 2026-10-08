import Foundation
import SwiftUI

private struct PendingSwipeConfirmation: Identifiable {
    let id = UUID()
    let action: TaskDetailAction
    let task: TaskModel
}

private extension TaskDetailAction {
    var needsHostConfirmation: Bool {
        self == .cancel || self == .delete
    }
}

private struct SwipeConfirmationHost<Content: View>: View {
    let perform: (TaskDetailAction, TaskModel) async -> Void
    @ViewBuilder let content: (@escaping (TaskDetailAction, TaskModel) -> Void) -> Content
    @State private var pending: PendingSwipeConfirmation?
    
    var body: some View {
        content { action, task in
            if action.needsHostConfirmation {
                pending = PendingSwipeConfirmation(action: action, task: task)
            } else {
                Task { await perform(action, task) }
            }
        }
        .confirmationDialog(
            pending.map { String(localized: $0.action.title) } ?? "",
            isPresented: Binding(
                get: { pending != nil },
                set: { if !$0 { pending = nil } }
            ),
            titleVisibility: .visible,
            presenting: pending
        ) { item in
            Button(String(localized: item.action.title), role: .destructive) {
                Task { await perform(item.action, item.task) }
            }
            Button("Keep", role: .cancel) {}
        }
    }
}

@ViewBuilder
private func swipeButtons(for actions: [TaskDetailAction], perform: @escaping (TaskDetailAction) -> Void) -> some View {
    ForEach(actions) { action in
        Button(role: action.role) {
            perform(action)
        } label: {
            Label(action.title, systemImage: action.systemImage)
        }
        .tint(action.color)
    }
}

func requesterSwipePerform(_ action: TaskDetailAction, task: TaskModel, vm: RequesterViewModel) async {
    switch action {
        case .applicants:
            await vm.showApplicants(for: task)
        case .confirmCompletion:
            await vm.confirmTaskCompletion(task)
        case .chats:
            vm.openChat(for: task.id)
        case .delete:
            await vm.deleteTask(task)
        case .cancel:
            await vm.cancelTask(task)
        case .publish:
            await vm.publishTask(task)
        case .pay:
            vm.startPayment(for: task)
        case .refund:
            vm.requestRefund(task)
        case .apply, .withdraw, .markDone:
            break
    }
}

func executorSwipePerform(_ action: TaskDetailAction, task: TaskModel, vm: ExecutorViewModel) async {
    switch action {
        case .apply:
            vm.beginApply(to: task)
        case .withdraw:
            vm.requestWithdraw(task)
        case .markDone:
            await vm.markTaskDone(task)
        case .chats:
            vm.openChat(for: task.id)
        case .applicants, .confirmCompletion, .delete, .cancel, .publish, .pay, .refund:
            break
    }
}

extension DIContainer {
    
    func makeRequesterPublishedTasksView() -> some View {
        SwipeConfirmationHost(
            perform: { [requesterViewModel] action, task in
                await requesterSwipePerform(action, task: task, vm: requesterViewModel)
            }
        ) { [self] request in
            TaskListView(
                tasks: requesterViewModel.requesterPublishedTasks,
                isLoading: requesterViewModel.isLoading,
                errorMessage: requesterViewModel.errorMessage,
                isLoadingMore: requesterViewModel.isLoadingMorePublishedTasks,
                loadingTitle: "Loading Published Tasks",
                emptyState: requesterViewModel.statusFilter == .all ? .noRequesterPublishedTasks : .noFilteredRequesterTasks,
                onLoad: { [requesterViewModel] in await requesterViewModel.loadPublishedTasks() },
                onLoadMoreIfNeeded: { [requesterViewModel] in await requesterViewModel.loadMorePublishedTasksIfNeeded() },
                onRefresh: { [requesterViewModel] in await requesterViewModel.loadPublishedTasks(showLoadingIndicator: false) },
                onClearFilter: { [requesterViewModel] in requesterViewModel.setStatusFilter(.all) },
                leadingSwipe: { task in
                    swipeButtons(for: TaskDetailAction.requesterActions(for: task).swipe(.leading)) { action in
                        request(action, task)
                    }
                },
                trailingSwipe: { task in
                    swipeButtons(for: TaskDetailAction.requesterActions(for: task).swipe(.trailing)) { action in
                        request(action, task)
                    }
                }
            )
        }
    }
    
    func makeRequesterCompletedTasksView() -> some View {
        TaskListView(
            tasks: requesterViewModel.requesterCompletedTasks,
            isLoading: requesterViewModel.isLoading,
            errorMessage: requesterViewModel.errorMessage,
            isLoadingMore: requesterViewModel.isLoadingMoreCompletedTasks,
            loadingTitle: "Loading completed tasks",
            emptyState: .noRequesterCompletedTasks,
            onLoad: { [requesterViewModel] in await requesterViewModel.loadCompletedTasks() },
            onLoadMoreIfNeeded: { [requesterViewModel] in await requesterViewModel.loadMoreCompletedTasksIfNeeded() },
            onRefresh: { [requesterViewModel] in await requesterViewModel.loadCompletedTasks(showLoadingIndicator: false) }
        )
    }
    
    func makeExecutorAvailableTasksView() -> some View {
        TaskListView(
            tasks: executorViewModel.executorAvailableTasks,
            isLoading: executorViewModel.isLoading,
            errorMessage: executorViewModel.errorMessage,
            isLoadingMore: executorViewModel.isLoadingMoreAvailableTasks,
            loadingTitle: "Loading available tasks",
            emptyState: executorViewModel.showFavoritesOnly ? .noExecutorFavoriteTasks : .noAvailableTasks,
            onLoad: { [executorViewModel] in await executorViewModel.loadAvailableTasks() },
            onLoadMoreIfNeeded: { [executorViewModel] in await executorViewModel.loadMoreAvailableTasksIfNeeded() },
            onRefresh: { [executorViewModel] in await executorViewModel.loadAvailableTasks(showLoadingIndicator: false) },
            onClearFilter: executorViewModel.showFavoritesOnly ? { [executorViewModel] in
                executorViewModel.showFavoritesOnly = false
            } : nil,
            onToggleFavorite: { [executorViewModel] task in
                Task { await executorViewModel.toggleFavorite(task) }
            },
            searchText: Binding(
                get: { [executorViewModel] in executorViewModel.searchText },
                set: { [executorViewModel] in executorViewModel.searchText = $0 }
            ),
            isSearchPresented: Binding(
                get: { [executorViewModel] in executorViewModel.isSearchPresented },
                set: { [executorViewModel] in executorViewModel.isSearchPresented = $0 }
            ),
            searchPrompt: "Search available tasks",
            leadingSwipe: { [executorViewModel] task in
                swipeButtons(for: TaskDetailAction.executorActions(for: task).swipe(.leading)) { action in
                    Task { await executorSwipePerform(action, task: task, vm: executorViewModel) }
                }
            },
            trailingSwipe: { [executorViewModel] task in
                swipeButtons(for: TaskDetailAction.executorActions(for: task).swipe(.trailing)) { action in
                    Task { await executorSwipePerform(action, task: task, vm: executorViewModel) }
                }
            }
        )
    }
    
    func makeExecutorAssignedTasksView() -> some View {
        TaskListView(
            tasks: executorViewModel.executorAssignedTasks,
            isLoading: executorViewModel.isLoading,
            errorMessage: executorViewModel.errorMessage,
            isLoadingMore: executorViewModel.isLoadingMoreAssignedTasks,
            loadingTitle: "Loading tasks assigned to you",
            emptyState: .noAssignedTasks,
            onLoad: { [executorViewModel] in await executorViewModel.loadAssignedTasks() },
            onLoadMoreIfNeeded: { [executorViewModel] in await executorViewModel.loadMoreAssignedTasksIfNeeded() },
            onRefresh: { [executorViewModel] in await executorViewModel.loadAssignedTasks(showLoadingIndicator: false) },
            leadingSwipe: { [executorViewModel] task in
                swipeButtons(for: TaskDetailAction.executorActions(for: task).swipe(.leading)) { action in
                    Task { await executorSwipePerform(action, task: task, vm: executorViewModel) }
                }
            },
            trailingSwipe: { [executorViewModel] task in
                swipeButtons(for: TaskDetailAction.executorActions(for: task).swipe(.trailing)) { action in
                    Task { await executorSwipePerform(action, task: task, vm: executorViewModel) }
                }
            }
        )
    }
    
    func makeExecutorCompletedTasksView() -> some View {
        TaskListView(
            tasks: executorViewModel.executorCompletedTasks,
            isLoading: executorViewModel.isLoading,
            errorMessage: executorViewModel.errorMessage,
            isLoadingMore: executorViewModel.isLoadingMoreCompletedTasks,
            loadingTitle: "Loading completed tasks",
            emptyState: .noExecutorCompletedTasks,
            onLoad: { [executorViewModel] in await executorViewModel.loadCompletedTasks() },
            onLoadMoreIfNeeded: { [executorViewModel] in await executorViewModel.loadMoreCompletedTasksIfNeeded() },
            onRefresh: { [executorViewModel] in await executorViewModel.loadCompletedTasks(showLoadingIndicator: false) }
        )
    }
}
