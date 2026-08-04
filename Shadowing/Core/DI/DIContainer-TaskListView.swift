import Foundation
import SwiftUI

extension DIContainer {
    func makeRequesterPublishedTasksView() -> TaskListView {
        TaskListView(
            tasks: requesterViewModel.requesterPublishedTasks,
            isLoading: requesterViewModel.isLoading,
            errorMessage: requesterViewModel.errorMessage,
            isLoadingMore: requesterViewModel.isLoadingMorePublishedTasks,
            loadingTitle: "Loading",
            loadingSubtitle: "Fetching your published tasks.",
            emptyState: requesterViewModel.statusFilter == .all ? .noRequesterPublishedTasks : .noFilteredRequesterTasks,
            onLoad: { [requesterViewModel] in await requesterViewModel.loadPublishedTasks() },
            onLoadMoreIfNeeded: { [requesterViewModel] in await requesterViewModel.loadMorePublishedTasksIfNeeded() },
            onClearFilter: { [requesterViewModel] in requesterViewModel.setStatusFilter(.all) },
            leadingSwipe: { [requesterViewModel] task in
                AnyView(
                    Group {
                        if task.status == TaskStatus.published.rawValue
                            || task.status == TaskStatus.pending.rawValue
                            || task.status == TaskStatus.cancelled.rawValue {
                            Button(role: .destructive) {
                                Task { await requesterViewModel.deleteTask(task) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            .tint(.red)
                            .appGlassCapsule()
                        }
                        
                        if task.status == TaskStatus.published.rawValue
                            || task.status == TaskStatus.pending.rawValue {
                            Button {
                                Task { await requesterViewModel.cancelTask(task) }
                            } label: {
                                Label("Cancel", systemImage: "xmark.circle")
                            }
                            .tint(.yellow)
                            .appGlassCapsule()
                        }
                        
                        if task.status == TaskStatus.cancelled.rawValue {
                            Button {
                                Task { await requesterViewModel.publishTask(task) }
                            } label: {
                                Label("Publish", systemImage: "square.and.arrow.up.badge.checkmark")
                            }
                            .tint(.blue)
                            .appGlassCapsule()
                        }
                    }
                )
            },
            trailingSwipe: { [requesterViewModel] task in
                AnyView(
                    Group {
                        
                        if task.status == TaskStatus.published.rawValue
                            || task.status == TaskStatus.pending.rawValue {
                            Button {
                                Task { await requesterViewModel.showApplicants(for: task) }
                            } label: {
                                Label("Applicants", systemImage: "person.3.fill")
                            }
                            .tint(.orange)
                            .appGlassCapsule()
                        }
                        if task.status == TaskStatus.pendingCompleted.rawValue {
                            Button {
                                Task { await requesterViewModel.confirmTaskCompletion(task) }
                            } label: {
                                Label("Completed", systemImage: "checkmark.seal")
                            }
                            .tint(.green)
                            .appGlassCapsule()
                        }
                        
                        if task.status == TaskStatus.inProgress.rawValue
                            || task.status == TaskStatus.pendingCompleted.rawValue {
                            Button {
                                requesterViewModel.openChat(for: task.id)
                            } label: {
                                Label("Chat", systemImage: "bubble.left.and.bubble.right.fill")
                            }
                            .tint(.blue)
                            .appGlassCapsule()
                        }
                    }
                )
            }
        )
    }
    func makeRequesterCompletedTasksView() -> TaskListView {
        TaskListView(
            tasks: requesterViewModel.requesterCompletedTasks,
            isLoading: requesterViewModel.isLoading,
            errorMessage: requesterViewModel.errorMessage,
            isLoadingMore: requesterViewModel.isLoadingMoreCompletedTasks,
            loadingTitle: "Loading",
            loadingSubtitle: "Fetching completed tasks.",
            emptyState: .noRequesterCompletedTasks,
            onLoad: { [requesterViewModel] in await requesterViewModel.loadCompletedTasks() },
            onLoadMoreIfNeeded: { [requesterViewModel] in await requesterViewModel.loadMoreCompletedTasksIfNeeded() }
        )
    }
    
    func makeExecutorAvailableTasksView() -> TaskListView {
        TaskListView(
            tasks: executorViewModel.executorAvailableTasks,
            isLoading: executorViewModel.isLoading,
            errorMessage: executorViewModel.errorMessage,
            isLoadingMore: executorViewModel.isLoadingMoreAvailableTasks,
            loadingTitle: "Loading",
            loadingSubtitle: "Fetching available tasks.",
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
                AnyView(
                    Group {
                        if (task.status == TaskStatus.published.rawValue
                            || task.status == TaskStatus.pending.rawValue) && !task.isApplicant {
                            Button {
                                executorViewModel.beginApply(to: task)
                            } label: {
                                Label("Accept", systemImage: "checkmark.circle")
                            }
                            .tint(.green)
                            .appGlassCapsule()
                            
                        } else if task.isApplicant {
                            Button {
                                Task { await executorViewModel.withdrawFromTask(task) }
                            } label: {
                                Label("Withdraw", systemImage: "arrow.uturn.backward")
                            }
                            .tint(.orange)
                            .appGlassCapsule()
                        }
                    }
                )
            }
        )
    }
    
    func makeExecutorAssignedTasksView() -> TaskListView {
        TaskListView(
            tasks: executorViewModel.executorAssignedTasks,
            isLoading: executorViewModel.isLoading,
            errorMessage: executorViewModel.errorMessage,
            isLoadingMore: executorViewModel.isLoadingMoreAssignedTasks,
            loadingTitle: "Loading",
            loadingSubtitle: "Fetching tasks assigned to you",
            emptyState: .noAssignedTasks,
            onLoad: { [executorViewModel] in await executorViewModel.loadAssignedTasks() },
            onLoadMoreIfNeeded: { [executorViewModel] in await executorViewModel.loadMoreAssignedTasksIfNeeded() },
            leadingSwipe: { [executorViewModel] task in
                AnyView(
                    Group {
                        if task.status == TaskStatus.inProgress.rawValue {
                            Button(role: .destructive) {
                                Task { await executorViewModel.withdrawFromTask(task) }
                            } label: {
                                Label("Withdraw", systemImage: "arrow.uturn.backward")
                            }
                            .tint(.red)
                            .appGlassCapsule()
                        }
                    }
                )
            },
            trailingSwipe: { [executorViewModel] task in
                AnyView(
                    Group {
                        if task.status == TaskStatus.inProgress.rawValue {
                            Button(role: .confirm) {
                                Task { await executorViewModel.markTaskDone(task) }
                            } label: {
                                Label("Done", systemImage: "checkmark.seal")
                            }
                            .tint(.green)
                            .appGlassCapsule()
                        }
                        
                        if task.status == TaskStatus.inProgress.rawValue
                            || task.status == TaskStatus.pendingCompleted.rawValue {
                            Button {
                                executorViewModel.openChat(for: task.id)
                            } label: {
                                Label("Chat", systemImage: "bubble.left.and.bubble.right.fill")
                            }
                            .tint(.blue)
                            .appGlassCapsule()
                        }
                    }
                )
            }
        )
    }
    
    func makeExecutorCompletedTasksView() -> TaskListView {
        TaskListView(
            tasks: executorViewModel.executorCompletedTasks,
            isLoading: executorViewModel.isLoading,
            errorMessage: executorViewModel.errorMessage,
            isLoadingMore: executorViewModel.isLoadingMoreCompletedTasks,
            loadingTitle: "Loading",
            loadingSubtitle: "Fetching completed tasks.",
            emptyState: .noExecutorCompletedTasks,
            onLoad: { [executorViewModel] in await executorViewModel.loadCompletedTasks() },
            onLoadMoreIfNeeded: { [executorViewModel] in await executorViewModel.loadMoreCompletedTasksIfNeeded() }
        )
    }
}
