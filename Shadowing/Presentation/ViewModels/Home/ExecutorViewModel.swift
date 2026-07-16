import Foundation

@MainActor
@Observable
final class ExecutorViewModel {
    
    var selectedTab: ExecutorTab = .availableTasks
    
    var isLoading = false
    var errorMessage: String?
    
    var executorAllTasks: [TaskModel] = []
    var executorAvailableTasks: [TaskModel] = []
    var executorAssignedTasks: [TaskModel] = []
    var executorCompletedTasks: [TaskModel] = []
    
    var isLoadingMoreAllTasks = false
    var isLoadingMoreAvailableTasks = false
    var isLoadingMoreAssignedTasks = false
    var isLoadingMoreCompletedTasks = false
    
    private var allTasksCursor: String?
    private var allTasksHasMore = true
    
    private var availableTasksCursor: String?
    private var availableTasksHasMore = true
    
    private var assignedTasksCursor: String?
    private var assignedTasksHasMore = true
    
    private var completedTasksCursor: String?
    private var completedTasksHasMore = true
    
    private let taskRepo: TaskRepositoryProtocol
    
        // Applied sheet state
    var showAppliedSheet: Bool = false
    var selectedTaskForApply: TaskModel?
    var isApplying = false
    
        // Rating sheet state
    var showRateRequesterSheet: Bool = false
    var selectedTaskIdForRating: String?
    var requesterName: String?
    
    var selectedTaskId: String?
    
    init(taskRepo: TaskRepositoryProtocol) {
        self.taskRepo = taskRepo
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
            try await taskRepo.applyToTask(id: task.id, proposedBudget: proposedBudget)
            showAppliedSheet = false
            selectedTaskForApply = nil
            await loadAvailableTasks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func withdrawFromTask(_ task: TaskModel) async {
        do {
            try await taskRepo.withdrawFromTask(id: task.id)
            await loadAvailableTasks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func markTaskDone(_ task: TaskModel) async {
        do {
            try await taskRepo.markTaskDone(id: task.id)
            await loadAssignedTasks()
            
            selectedTaskIdForRating = task.id
            requesterName = task.requester.displayName
            showRateRequesterSheet = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
        // MARK: - All Tasks
    func loadAllTasks() async {
        isLoading = true
        errorMessage = nil
        allTasksCursor = nil
        allTasksHasMore = true
        defer { isLoading = false }
        
        do {
            let result = try await taskRepo.getAllTasks(cursor: nil, limit: nil)
            executorAllTasks = result.tasks
            allTasksHasMore = result.hasMore
            allTasksCursor = result.cursor
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func loadMoreAllTasksIfNeeded() async {
        guard shouldLoadMore(
            hasMore: allTasksHasMore,
            isLoadingMore: isLoadingMoreAllTasks
        ) else { return }
        
        isLoadingMoreAllTasks = true
        defer { isLoadingMoreAllTasks = false }
        
        do {
            let result = try await taskRepo.getAllTasks(cursor: availableTasksCursor, limit: nil)
            executorAllTasks.append(contentsOf: result.tasks)
            allTasksHasMore = result.hasMore
            allTasksCursor = result.cursor
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
        // MARK: - Available Tasks
    
    func loadAvailableTasks() async {
        isLoading = true
        errorMessage = nil
        availableTasksCursor = nil
        availableTasksHasMore = true
        defer { isLoading = false }
        
        do {
            let result = try await taskRepo.getExecutorAvailableTasks(cursor: nil, limit: nil)
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
        ) else { return }
        
        isLoadingMoreAvailableTasks = true
        defer { isLoadingMoreAvailableTasks = false }
        
        do {
            let result = try await taskRepo.getExecutorAvailableTasks(cursor: availableTasksCursor, limit: nil)
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
        defer { isLoading = false }
        
        do {
            let result = try await taskRepo.getExecutorAssignedTasks(cursor: nil, limit: nil)
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
        ) else { return }
        
        isLoadingMoreAssignedTasks = true
        defer { isLoadingMoreAssignedTasks = false }
        
        do {
            let result = try await taskRepo.getExecutorAssignedTasks(cursor: assignedTasksCursor, limit: nil)
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
        defer { isLoading = false }
        
        do {
            let result = try await taskRepo.getExecutorCompletedTasks(cursor: nil, limit: nil)
            executorCompletedTasks = result.tasks
            completedTasksHasMore = result.hasMore
            completedTasksCursor = result.cursor
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func loadMoreCompletedTasksIfNeeded() async {
        guard shouldLoadMore(
            hasMore: completedTasksHasMore,
            isLoadingMore: isLoadingMoreCompletedTasks
        ) else { return }
        
        isLoadingMoreCompletedTasks = true
        defer { isLoadingMoreCompletedTasks = false }
        
        do {
            let result = try await taskRepo.getExecutorCompletedTasks(cursor: completedTasksCursor, limit: nil)
            executorCompletedTasks.append(contentsOf: result.tasks)
            completedTasksHasMore = result.hasMore
            completedTasksCursor = result.cursor
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
        // MARK: - Helpers
    
        /// Triggers when the visible row is within the last 5 items of the current list.
    private func shouldLoadMore(hasMore: Bool, isLoadingMore: Bool) -> Bool {
        return hasMore && !isLoadingMore
    }
}
