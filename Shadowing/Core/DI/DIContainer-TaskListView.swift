import Foundation
import SwiftUI

    // MARK: - Shared Swipe Action Rendering

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
        case .accept, .withdraw, .markDone:
            break // Not applicable to the requester role
    }
}

func executorSwipePerform(_ action: TaskDetailAction, task: TaskModel, vm: ExecutorViewModel) async {
    switch action {
        case .accept:
            vm.beginApply(to: task)
        case .withdraw:
            await vm.withdrawFromTask(task)
        case .markDone:
            await vm.markTaskDone(task)
        case .chats:
            vm.openChat(for: task.id)
        case .applicants, .confirmCompletion, .delete, .cancel, .publish:
            break // Not applicable to the executor role
    }
}

extension DIContainer {
    
        // MARK: - Requester Views
    
    func makeRequesterPublishedTasksView() -> some View {
        TaskListView(
            tasks: requesterViewModel.requesterPublishedTasks,
            isLoading: requesterViewModel.isLoading,
            errorMessage: requesterViewModel.errorMessage,
            isLoadingMore: requesterViewModel.isLoadingMorePublishedTasks,
            loadingTitle: "Loading Published Tasks",
            emptyState: requesterViewModel.statusFilter == .all ? .noRequesterPublishedTasks : .noFilteredRequesterTasks,
            onLoad: { [requesterViewModel] in await requesterViewModel.loadPublishedTasks() },
            onLoadMoreIfNeeded: { [requesterViewModel] in await requesterViewModel.loadMorePublishedTasksIfNeeded() },
            onClearFilter: { [requesterViewModel] in requesterViewModel.setStatusFilter(.all) },
            leadingSwipe: { [requesterViewModel] task in
                swipeButtons(for: TaskDetailAction.requesterActions(for: task).leading) { action in
                    Task { await requesterSwipePerform(action, task: task, vm: requesterViewModel)}
                }
                
            },
            trailingSwipe: { [requesterViewModel] task in
                swipeButtons(for: TaskDetailAction.requesterActions(for: task).trailing) { action in
                    Task { await requesterSwipePerform(action, task: task, vm: requesterViewModel) }
                }
            }
        )
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
            onLoadMoreIfNeeded: { [requesterViewModel] in await requesterViewModel.loadMoreCompletedTasksIfNeeded() }
        )
    }
    
        // MARK: - Executor Views
    
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
            onClearFilter: executorViewModel.showFavoritesOnly ? { [executorViewModel] in
                executorViewModel.showFavoritesOnly = false
            } : nil,
            onToggleFavorite: { [executorViewModel] task in
                Task { await executorViewModel.toggleFavorite(task) }
            },
            trailingSwipe: { [executorViewModel] task in
                swipeButtons(for: TaskDetailAction.executorActions(for: task).trailing) { action in
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
            leadingSwipe: { [executorViewModel] task in
                swipeButtons(for: TaskDetailAction.executorActions(for: task).leading) { action in
                    Task { await executorSwipePerform(action, task: task, vm: executorViewModel) }
                }
            },
            trailingSwipe: { [executorViewModel] task in
                swipeButtons(for: TaskDetailAction.executorActions(for: task).trailing) { action in
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
            onLoadMoreIfNeeded: { [executorViewModel] in await executorViewModel.loadMoreCompletedTasksIfNeeded() }
        )
    }
}
