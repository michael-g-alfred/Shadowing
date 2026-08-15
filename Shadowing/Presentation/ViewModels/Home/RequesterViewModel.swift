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
    
        /// Set on a successful assign; ApplicantsSheet shows this as a local
        /// alert (so it can appear above the sheet) and dismisses the sheet
        /// itself only when the user taps OK.
    var assignResult: (message: String, type: String)?
    
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
    private let notificationRepo: NotificationRepositoryProtocol
    private let authRepo: AuthRepositoryProtocol
    
    init(
        taskRepo: TaskRepositoryProtocol,
        chatRepo: ChatRepositoryProtocol,
        userRepo: UserRepositoryProtocol,
        notificationRepo: NotificationRepositoryProtocol,
        authRepo: AuthRepositoryProtocol
    ) {
        self.taskRepo = taskRepo
        self.chatRepo = chatRepo
        self.userRepo = userRepo
        self.notificationRepo = notificationRepo
        self.authRepo = authRepo
    }
    
    func select(_ tab: RequesterTab) {
        selectedTab = tab
    }
    
    func assignExecutor(_ applicant: ApplicantModel) async {
        guard let task = selectedTaskForApplicants else { return }
        isAssigningExecutor = true
        defer { isAssigningExecutor = false }
        
        do {
            let result = try await taskRepo.assignExecutor(taskId: task.id, executorId: applicant.id)
            
            let requesterId = task.requester.id
            try await chatRepo.createChat(taskId: task.id, requesterId: requesterId, executorId: applicant.id)
            
            await notifyExecutorOfAssignment(applicant, for: task)
            
            assignResult = result
        } catch {
            AlertCenter.shared.showError(error.localizedDescription)
        }
    }
    
        /// Called when the user taps OK on the assign-success alert inside
        /// ApplicantsSheet — closes the sheet only now, so the alert and the
        /// sheet dismissal never race each other.
    func dismissAssignSuccessAlert() {
            // 1. Local state mutation: update task status to inProgress instead of fetching all tasks
        if let task = selectedTaskForApplicants,
           let index = requesterPublishedTasks.firstIndex(where: { $0.id == task.id }) {
            requesterPublishedTasks[index].status = TaskStatus.inProgress.rawValue
        }
        
            // 2. Clear state and dismiss sheet
        assignResult = nil
        showApplicantsSheet = false
        selectedTaskApplicants = []
        selectedTaskForApplicants = nil
    }
    
    func confirmTaskCompletion(_ task: TaskModel) async {
            // Optimistic update: Remove immediately from published list
        guard let index = requesterPublishedTasks.firstIndex(where: { $0.id == task.id }) else { return }
        let removedTask = requesterPublishedTasks.remove(at: index)
        
        do {
            let result = try await taskRepo.confirmTask(id: task.id)
            try await chatRepo.deleteChat(taskId: task.id)
            AlertCenter.shared.show(responseType: result.type, message: result.message)
            await notifyExecutorOfConfirmation(for: task)
            await checkPendingRatings()
        } catch {
                // Rollback in case of failure
            requesterPublishedTasks.insert(removedTask, at: index)
            AlertCenter.shared.showError(error.localizedDescription)
        }
    }
    
    func deleteTask(_ task: TaskModel) async {
            // Optimistic update: Remove task directly
        guard let index = requesterPublishedTasks.firstIndex(where: { $0.id == task.id }) else { return }
        let removedTask = requesterPublishedTasks.remove(at: index)
        
        do {
            let result = try await taskRepo.deleteTask(id: task.id)
            AlertCenter.shared.show(responseType: result.type, message: result.message)
        } catch {
                // Rollback in case of failure
            requesterPublishedTasks.insert(removedTask, at: index)
            AlertCenter.shared.showError(error.localizedDescription)
        }
    }
    
    func cancelTask(_ task: TaskModel) async {
        guard let index = requesterPublishedTasks.firstIndex(where: { $0.id == task.id }) else { return }
        let previousTask = requesterPublishedTasks[index]
        
            // 1. Optimistic local state mutation
        requesterPublishedTasks[index].status = TaskStatus.cancelled.rawValue
        
        do {
            let result = try await taskRepo.cancelTask(id: task.id)
            AlertCenter.shared.show(responseType: result.type, message: result.message)
            await notifyExecutorOfCancellation(for: task)
        } catch {
                // 2. Rollback on failure
            requesterPublishedTasks[index] = previousTask
            AlertCenter.shared.showError(error.localizedDescription)
        }
    }
    
    func publishTask(_ task: TaskModel) async {
        guard let index = requesterPublishedTasks.firstIndex(where: { $0.id == task.id }) else { return }
        let previousTask = requesterPublishedTasks[index]
        
            // 1. Optimistic local state mutation
        requesterPublishedTasks[index].status = TaskStatus.published.rawValue
        
        do {
            let result = try await taskRepo.publishTask(id: task.id)
            AlertCenter.shared.show(responseType: result.type, message: result.message)
        } catch {
                // 2. Rollback on failure
            requesterPublishedTasks[index] = previousTask
            AlertCenter.shared.showError(error.localizedDescription)
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
        
            // Optimistic removal of applicant from local state
        let previousApplicants = selectedTaskApplicants
        selectedTaskApplicants.removeAll { $0.id == applicant.id }
        
        do {
            let result = try await taskRepo.declineApplicant(taskId: task.id, applicantId: applicant.id)
            AlertCenter.shared.show(responseType: result.type, message: result.message)
            await notifyApplicantOfDecline(applicant, for: task)
        } catch {
            selectedTaskApplicants = previousApplicants
            AlertCenter.shared.showError(error.localizedDescription)
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
        self.selectedChatTaskId = taskId
    }
    
        // MARK: - Notifications
        /// Fire-and-forget: a failed notification send should never block or
        /// roll back the task action that triggered it, so failures are swallowed.
    
    private var currentUserDisplayName: String {
        authRepo.currentUser?.displayName ?? "Someone"
    }
    
    private func notifyExecutorOfAssignment(_ applicant: ApplicantModel, for task: TaskModel) async {
        try? await notificationRepo.send(
            to: applicant.id,
            type: .taskAccepted,
            title: "You're assigned!",
            body: "\(currentUserDisplayName) assigned you to \"\(task.title)\"",
            taskId: task.id
        )
    }
    
    private func notifyExecutorOfConfirmation(for task: TaskModel) async {
        guard let executorId = task.executor?.id else { return }
        try? await notificationRepo.send(
            to: executorId,
            type: .taskConfirmed,
            title: "Task confirmed!",
            body: "\(currentUserDisplayName) confirmed completion of \"\(task.title)\"",
            taskId: task.id
        )
    }
    
    private func notifyApplicantOfDecline(_ applicant: ApplicantModel, for task: TaskModel) async {
        try? await notificationRepo.send(
            to: applicant.id,
            type: .taskDeclined,
            title: "Application declined",
            body: "\(currentUserDisplayName) declined your application for \"\(task.title)\"",
            taskId: task.id
        )
    }
    
        /// Only relevant if the task already had an executor assigned when it was
        /// cancelled — a task cancelled while still unassigned has no one to notify.
    private func notifyExecutorOfCancellation(for task: TaskModel) async {
        guard let executorId = task.executor?.id else { return }
        try? await notificationRepo.send(
            to: executorId,
            type: .taskCancelled,
            title: "Task cancelled",
            body: "\(currentUserDisplayName) cancelled \"\(task.title)\"",
            taskId: task.id
        )
    }
    
        // MARK: - Helpers
    
        /// Triggers when the visible row is within the last 5 items of the current list.
    private func shouldLoadMore(hasMore: Bool, isLoadingMore: Bool) -> Bool {
        return hasMore && !isLoadingMore
    }
}
