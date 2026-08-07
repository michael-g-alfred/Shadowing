import Foundation

@MainActor
@Observable
final class ExecutorViewModel {
    
    var selectedTab: ExecutorTab = .availableTasks
    
    var isLoading = false
    var errorMessage: String?
    
    var executorAvailableTasks: [TaskModel] = []
    var executorAssignedTasks: [TaskModel] = []
    var executorCompletedTasks: [TaskModel] = []
    
    var isLoadingMoreAvailableTasks = false
    var isLoadingMoreAssignedTasks = false
    var isLoadingMoreCompletedTasks = false
    
    private var availableTasksCursor: String?
    private var availableTasksHasMore = true
    private var availableTasksGeneration = 0
    
    var showFavoritesOnly = false {
        didSet {
            guard oldValue != showFavoritesOnly else { return }
            Task { await loadAvailableTasks() }
        }
    }
    
    private var assignedTasksCursor: String?
    private var assignedTasksHasMore = true
    private var assignedTasksGeneration = 0
    
    private var completedTasksCursor: String?
    private var completedTasksHasMore = true
    private var completedTasksGeneration = 0
    
    private let taskRepo: TaskRepositoryProtocol
    private let chatRepo: ChatRepositoryProtocol
    
        // Applied sheet state
    var showAppliedSheet: Bool = false
    var selectedTaskForApply: TaskModel?
    var isApplying = false
    
        // MARK: - Rating Queue
    
    private(set) var pendingRatingTasks: [TaskModel] = []
    
    var currentRatingTask: TaskModel? {
        pendingRatingTasks.first
    }
    
    var selectedTaskId: String?
    
    var selectedChatTaskId: String?
    
    init(taskRepo: TaskRepositoryProtocol, chatRepo: ChatRepositoryProtocol) {
        self.taskRepo = taskRepo
        self.chatRepo = chatRepo
    }
    
    func beginApply(to task: TaskModel) {
        selectedTaskForApply = task
        showAppliedSheet = true
    }
    
    func select(_ tab: ExecutorTab) {
        selectedTab = tab
    }
    
        // MARK: - Task Actions
    
    func acceptTask(_ task: TaskModel, proposedBudget: Double? = nil) async {
        isApplying = true
        defer { isApplying = false }
        
        do {
            let result = try await taskRepo.applyToTask(id: task.id, proposedBudget: proposedBudget)
            showAppliedSheet = false
            selectedTaskForApply = nil
            AlertCenter.shared.show(responseType: result.type, message: result.message)
            await loadAvailableTasks()
        } catch {
            AlertCenter.shared.showError(error.localizedDescription)
        }
    }
    
    func withdrawFromTask(_ task: TaskModel) async {
        do {
            let result = try await taskRepo.withdrawFromTask(id: task.id)
            
            if let warning = result.warning {
                AlertCenter.shared.show(responseType: result.type, message: warning)
            } else {
                AlertCenter.shared.show(responseType: result.type, message: result.message)
            }
            
            if task.status == TaskStatus.inProgress.rawValue {
                try? await chatRepo.deleteChat(taskId: task.id)
                await loadAssignedTasks()
            } else {
                await loadAvailableTasks()
            }
        } catch {
            AlertCenter.shared.showError(error.localizedDescription)
        }
    }
    
    func markTaskDone(_ task: TaskModel) async {
        do {
            let result = try await taskRepo.markTaskDone(id: task.id)
            AlertCenter.shared.show(responseType: result.type, message: result.message)
            await loadAssignedTasks()
        } catch {
            AlertCenter.shared.showError(error.localizedDescription)
        }
    }
    
        // MARK: - Favorites
    
    func toggleFavorite(_ task: TaskModel) async {
        let newValue = !task.isFavourite
        setFavourite(newValue, forTaskId: task.id)
        
        do {
            let result: (message: String, type: String)
            if newValue {
                result = try await taskRepo.favoriteTask(id: task.id)
            } else {
                result = try await taskRepo.unfavoriteTask(id: task.id)
            }
            
            if showFavoritesOnly && !newValue {
                executorAvailableTasks.removeAll { $0.id == task.id }
            }
            
            AlertCenter.shared.show(responseType: result.type, message: result.message)
            
        } catch {
            setFavourite(!newValue, forTaskId: task.id)
            AlertCenter.shared.showError(error.localizedDescription)
        }
    }
    
    private func setFavourite(_ isFavourite: Bool, forTaskId taskId: String) {
        if let idx = executorAvailableTasks.firstIndex(where: { $0.id == taskId }) {
            executorAvailableTasks[idx].isFavourite = isFavourite
        }
    }
    
        // MARK: - Rating Queue
    
    func checkPendingRatings() async {
        do {
            let result = try await taskRepo.getUnratedExecutorTasks(cursor: nil, limit: nil)
            let unrated = result.tasks
            
            for task in unrated where !pendingRatingTasks.contains(where: { $0.id == task.id }) {
                pendingRatingTasks.append(task)
            }
            
            let unratedIds = Set(unrated.map(\.id))
            pendingRatingTasks.removeAll { !unratedIds.contains($0.id) }
            
        } catch {
                // Silent failure here is fine — this is a background catch-up check,
                // not a user-initiated action. Don't surface errorMessage for it.
        }
    }
    
        /// Called when the rating sheet for this task is dismissed (submitted or not).
        /// If it wasn't submitted, checkPendingRatings() will pick it back up later.
    func ratingSheetDismissed(for taskId: String, wasSubmitted: Bool) {
        if wasSubmitted {
            pendingRatingTasks.removeAll { $0.id == taskId }
        }
            // If not submitted, leave it in the queue so it re-shows next time
            // (e.g. .sheet(item:) will re-present it since it's still first in queue).
    }
    
        // MARK: - Available Tasks
    
    func loadAvailableTasks() async {
        isLoading = true
        errorMessage = nil
        availableTasksCursor = nil
        availableTasksHasMore = true
        availableTasksGeneration += 1
        let myGeneration = availableTasksGeneration
        defer { isLoading = false }
        
        do {
            let result = try await taskRepo.getExecutorAvailableTasks(cursor: nil, limit: nil, favoritesOnly: showFavoritesOnly)
            guard myGeneration == availableTasksGeneration else { return }
            executorAvailableTasks = result.tasks
            availableTasksHasMore = result.hasMore
            availableTasksCursor = result.cursor
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func loadMoreAvailableTasksIfNeeded() async {
        guard shouldLoadMore(
            hasMore: availableTasksHasMore,
            isLoadingMore: isLoadingMoreAvailableTasks
        ), !isLoading else { return }
        
        isLoadingMoreAvailableTasks = true
        let myGeneration = availableTasksGeneration
        defer { isLoadingMoreAvailableTasks = false }
        
        do {
            let result = try await taskRepo.getExecutorAvailableTasks(cursor: availableTasksCursor, limit: nil, favoritesOnly: showFavoritesOnly)
            guard myGeneration == availableTasksGeneration else { return }
            executorAvailableTasks.append(contentsOf: result.tasks)
            availableTasksHasMore = result.hasMore
            availableTasksCursor = result.cursor
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
        // MARK: - Assigned Tasks
    
    func loadAssignedTasks() async {
        isLoading = true
        errorMessage = nil
        assignedTasksCursor = nil
        assignedTasksHasMore = true
        assignedTasksGeneration += 1
        let myGeneration = assignedTasksGeneration
        defer { isLoading = false }
        
        do {
            let result = try await taskRepo.getExecutorAssignedTasks(cursor: nil, limit: nil)
            guard myGeneration == assignedTasksGeneration else { return }
            executorAssignedTasks = result.tasks
            assignedTasksHasMore = result.hasMore
            assignedTasksCursor = result.cursor
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func loadMoreAssignedTasksIfNeeded() async {
        guard shouldLoadMore(
            hasMore: assignedTasksHasMore,
            isLoadingMore: isLoadingMoreAssignedTasks
        ), !isLoading else { return }
        
        isLoadingMoreAssignedTasks = true
        let myGeneration = assignedTasksGeneration
        defer { isLoadingMoreAssignedTasks = false }
        
        do {
            let result = try await taskRepo.getExecutorAssignedTasks(cursor: assignedTasksCursor, limit: nil)
            guard myGeneration == assignedTasksGeneration else { return }
            executorAssignedTasks.append(contentsOf: result.tasks)
            assignedTasksHasMore = result.hasMore
            assignedTasksCursor = result.cursor
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
        // MARK: - Completed Tasks
    
    func loadCompletedTasks() async {
        isLoading = true
        errorMessage = nil
        completedTasksCursor = nil
        completedTasksHasMore = true
        completedTasksGeneration += 1
        let myGeneration = completedTasksGeneration
        defer { isLoading = false }
        
        do {
            let result = try await taskRepo.getExecutorCompletedTasks(cursor: nil, limit: nil)
            guard myGeneration == completedTasksGeneration else { return }
            executorCompletedTasks = result.tasks
            completedTasksHasMore = result.hasMore
            completedTasksCursor = result.cursor
        } catch {
            errorMessage = error.localizedDescription
        }
        
            // Piggyback the pending-rating check whenever completed tasks are (re)loaded.
        await checkPendingRatings()
    }
    
    func loadMoreCompletedTasksIfNeeded() async {
        guard shouldLoadMore(
            hasMore: completedTasksHasMore,
            isLoadingMore: isLoadingMoreCompletedTasks
        ), !isLoading else { return }
        
        isLoadingMoreCompletedTasks = true
        let myGeneration = completedTasksGeneration
        defer { isLoadingMoreCompletedTasks = false }
        
        do {
            let result = try await taskRepo.getExecutorCompletedTasks(cursor: completedTasksCursor, limit: nil)
            guard myGeneration == completedTasksGeneration else { return }
            executorCompletedTasks.append(contentsOf: result.tasks)
            completedTasksHasMore = result.hasMore
            completedTasksCursor = result.cursor
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
        // MARK: - Chat
    
    func openChat(for taskId: String) {
        self.selectedChatTaskId = taskId
    }
    
        // MARK: - Helpers
    
        /// Triggers when the visible row is within the last 5 items of the current list.
    private func shouldLoadMore(hasMore: Bool, isLoadingMore: Bool) -> Bool {
        return hasMore && !isLoadingMore
    }
}
