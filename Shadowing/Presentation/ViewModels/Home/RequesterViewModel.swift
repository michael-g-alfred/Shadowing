import Foundation

@MainActor
@Observable
final class RequesterViewModel {
    var selectedTab: RequesterTab = .publishedTasks
    var isLoading = false
    var errorMessage: String?
    
    var requesterPublishedTasks: [TaskModel] = []
    var requesterCompletedTasks: [TaskModel] = []
    
    var isLoadingMorePublishedTasks = false
    var isLoadingMoreCompletedTasks = false
    
    private var publishedTasksCursor: String?
    private var publishedTasksHasMore = true
    private var publishedTasksGeneration = 0
    private var completedTasksCursor: String?
    private var completedTasksHasMore = true
    private var completedTasksGeneration = 0
    
    var showAddTaskSheet: Bool = false
    
    var showApplicantsSheet: Bool = false
    var selectedTaskApplicants: [ApplicantModel] = []
    var isLoadingApplicants = false
    var selectedTaskForApplicants: TaskModel?
    var isAssigningExecutor = false
    
    var selectedTaskId: String?
    
    var statusFilter: RequesterStatusFilter = .all
    
    var selectedChatTaskId: String?
    
        // MARK: - Rating Queue
        /// Completed tasks that this requester still needs to rate the executor for.
        /// Driven by `status == .completed && !isRatedByRequester`, NOT by confirmTaskCompletion directly.
    private(set) var pendingRatingTasks: [TaskModel] = []
    
        /// The task currently presented in the rating sheet. Drives `.sheet(item:)`.
    var currentRatingTask: TaskModel? {
        pendingRatingTasks.first
    }
    
    private let taskRepo: TaskRepositoryProtocol
    private let chatRepo: ChatRepositoryProtocol
    private let userRepo: UserRepositoryProtocol
    
    init(taskRepo: TaskRepositoryProtocol, chatRepo: ChatRepositoryProtocol, userRepo: UserRepositoryProtocol) {
        self.taskRepo = taskRepo
        self.chatRepo = chatRepo
        self.userRepo = userRepo
    }
    
    func select(_ tab: RequesterTab) {
        selectedTab = tab
    }
    
    func assignExecutor(_ applicant: ApplicantModel) async {
        guard let task = selectedTaskForApplicants else { return }
        isAssigningExecutor = true
        defer { isAssigningExecutor = false }
        
        do {
            try await taskRepo.assignExecutor(taskId: task.id, executorId: applicant.id)
            
            let requesterId = task.requester.id
            try await chatRepo.createChat(taskId: task.id, requesterId: requesterId, executorId: applicant.id)
            
            showApplicantsSheet = false
            selectedTaskApplicants = []
            selectedTaskForApplicants = nil
            await loadPublishedTasks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func confirmWithdraw(_ task: TaskModel) async {
        do {
            try await taskRepo.confirmWithdraw(taskId: task.id)
            try await chatRepo.deleteChat(taskId: task.id)
            requesterPublishedTasks.removeAll { $0.id == task.id }
            await loadPublishedTasks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func confirmTaskCompletion(_ task: TaskModel) async {
        do {
            try await taskRepo.confirmTask(id: task.id)
            try await chatRepo.deleteChat(taskId: task.id)
            requesterPublishedTasks.removeAll { $0.id == task.id }
            await checkPendingRatings()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func deleteTask(_ task: TaskModel) async {
        do {
            try await taskRepo.deleteTask(id: task.id)
            requesterPublishedTasks.removeAll { $0.id == task.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func cancelTask(_ task: TaskModel) async {
        do {
            try await taskRepo.cancelTask(id: task.id)
            await loadPublishedTasks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func publishTask(_ task: TaskModel) async {
        do {
            try await taskRepo.publishTask(id: task.id)
            await loadPublishedTasks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func showApplicants(for task: TaskModel) async {
        selectedTaskForApplicants = task
        isLoadingApplicants = true
        showApplicantsSheet = true
        defer { isLoadingApplicants = false }
        
        do {
            selectedTaskApplicants = try await taskRepo.getApplicants(taskId: task.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func declineApplicant(_ applicant: ApplicantModel) async {
        guard let task = selectedTaskForApplicants else { return }
        do {
            try await taskRepo.declineApplicant(taskId: task.id, applicantId: applicant.id)
            selectedTaskApplicants.removeAll { $0.id == applicant.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func setStatusFilter(_ filter: RequesterStatusFilter) {
        statusFilter = filter
        Task { await loadPublishedTasks() }
    }
    
    func loadPublishedTasks() async {
        isLoading = true
        errorMessage = nil
        publishedTasksCursor = nil
        publishedTasksHasMore = true
        publishedTasksGeneration += 1
        let myGeneration = publishedTasksGeneration
        defer { isLoading = false }
        
        do {
            let result = try await taskRepo.getRequesterPublishedTasks(
                cursor: nil,
                limit: nil,
                status: statusFilter.apiValue
            )
            guard myGeneration == publishedTasksGeneration else { return }
            requesterPublishedTasks = result.tasks
            publishedTasksHasMore = result.hasMore
            publishedTasksCursor = result.cursor
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func loadMorePublishedTasksIfNeeded() async {
        guard shouldLoadMore(hasMore: publishedTasksHasMore, isLoadingMore: isLoadingMorePublishedTasks),
              !isLoading else { return }
        isLoadingMorePublishedTasks = true
        let myGeneration = publishedTasksGeneration
        defer { isLoadingMorePublishedTasks = false }
        
        do {
            let result = try await taskRepo.getRequesterPublishedTasks(
                cursor: publishedTasksCursor,
                limit: nil,
                status: statusFilter.apiValue
            )
            guard myGeneration == publishedTasksGeneration else { return }
            requesterPublishedTasks.append(contentsOf: result.tasks)
            publishedTasksHasMore = result.hasMore
            publishedTasksCursor = result.cursor
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func loadCompletedTasks() async {
        isLoading = true
        errorMessage = nil
        completedTasksCursor = nil
        completedTasksHasMore = true
        completedTasksGeneration += 1
        let myGeneration = completedTasksGeneration
        defer { isLoading = false }
        
        do {
            let result = try await taskRepo.getRequesterCompletedTasks(cursor: nil, limit: nil)
            guard myGeneration == completedTasksGeneration else { return }
            requesterCompletedTasks = result.tasks
            completedTasksHasMore = result.hasMore
            completedTasksCursor = result.cursor
        } catch {
            errorMessage = error.localizedDescription
        }
        
            // Piggyback the pending-rating check whenever completed tasks are (re)loaded.
        await checkPendingRatings()
    }
    
    func loadMoreCompletedTasksIfNeeded() async {
        guard shouldLoadMore(hasMore: completedTasksHasMore, isLoadingMore: isLoadingMoreCompletedTasks),
              !isLoading else { return }
        isLoadingMoreCompletedTasks = true
        let myGeneration = completedTasksGeneration
        defer { isLoadingMoreCompletedTasks = false }
        
        do {
            let result = try await taskRepo.getRequesterCompletedTasks(cursor: completedTasksCursor, limit: nil)
            guard myGeneration == completedTasksGeneration else { return }
            requesterCompletedTasks.append(contentsOf: result.tasks)
            completedTasksHasMore = result.hasMore
            completedTasksCursor = result.cursor
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
        // MARK: - Rating Queue
    
        /// Call this on tab appear / app launch to pick up any completed tasks
        /// that are still missing this requester's rating of the executor.
    func checkPendingRatings() async {
        do {
            let result = try await taskRepo.getUnratedRequesterTasks(cursor: nil, limit: nil)
            let unrated = result.tasks
            
            for task in unrated where !pendingRatingTasks.contains(where: { $0.id == task.id }) {
                pendingRatingTasks.append(task)
            }
            let unratedIds = Set(unrated.map(\.id))
            pendingRatingTasks.removeAll { !unratedIds.contains($0.id) }
        } catch {
                // Silent failure — background catch-up check, not user-initiated.
        }
    }
    
        /// Called when the rating sheet for this task is dismissed (submitted or not).
    func ratingSheetDismissed(for taskId: String, wasSubmitted: Bool) {
        if wasSubmitted {
            pendingRatingTasks.removeAll { $0.id == taskId }
        }
    }
    
        // MARK: - Chat
    
    func openChat(for taskId: String) {
        DebugLogger.log("Opening chat for task: \(taskId)")
        self.selectedChatTaskId = taskId
    }
    
        // MARK: - Helpers
    
        /// Triggers when the visible row is within the last 5 items of the current list.
    private func shouldLoadMore(hasMore: Bool, isLoadingMore: Bool) -> Bool {
        return hasMore && !isLoadingMore
    }
}
