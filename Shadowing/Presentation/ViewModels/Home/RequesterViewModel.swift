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
    
    var showAddTaskSheet = false
    
    var showApplicantsSheet = false
    var selectedTaskApplicants: [ApplicantModel] = []
    var isLoadingApplicants = false
    var selectedTaskForApplicants: TaskModel?
    var isAssigningExecutor = false
    
        /// Set on a successful assign.
        /// ApplicantsSheet shows this as a local alert.
    var assignResult: (message: String, type: String)?
    
    var selectedTaskId: String?
    
    var statusFilter: RequesterStatusFilter = .all
    
    var selectedChatTaskId: String?
    
        // MARK: - Rating Queue
    
        /// Completed tasks that this requester still needs to rate
        /// the executor for.
        ///
        /// Driven by the server-side unrated-task query and NOT by
        /// confirmTaskCompletion directly.
    private(set) var pendingRatingTasks: [TaskModel] = []
    
        /// The task currently presented in the rating sheet.
    var currentRatingTask: TaskModel? {
        pendingRatingTasks.first
    }
    
        // MARK: - Dependencies
    
    private let authRepo: AuthRepositoryProtocol
    private let userRepo: UserRepositoryProtocol
    private let taskRepo: TaskRepositoryProtocol
    private let chatRepo: ChatRepositoryProtocol
    private let notificationRepo: NotificationRepositoryProtocol
    
        // MARK: - Init
    
    init(
        authRepo: AuthRepositoryProtocol,
        userRepo: UserRepositoryProtocol,
        taskRepo: TaskRepositoryProtocol,
        chatRepo: ChatRepositoryProtocol,
        notificationRepo: NotificationRepositoryProtocol
    ) {
        self.taskRepo = taskRepo
        self.userRepo = userRepo
        self.chatRepo = chatRepo
        self.notificationRepo = notificationRepo
        self.authRepo = authRepo
    }
    
        // MARK: - Navigation
    
    func select(_ tab: RequesterTab) {
        selectedTab = tab
    }
    
        // MARK: - Assign Executor
    
    func assignExecutor(_ applicant: ApplicantModel) async {
        guard let task = selectedTaskForApplicants else {
            return
        }
        
        isAssigningExecutor = true
        defer {
            isAssigningExecutor = false
        }
        
        do {
            let result = try await taskRepo.assignExecutor(
                taskId: task.id,
                executorId: applicant.id
            )
            
            let requesterId = task.requester.id
            
            try await chatRepo.createChat(
                taskId: task.id,
                requesterId: requesterId,
                executorId: applicant.id
            )
            
            await notifyExecutorOfAssignment(
                applicant,
                for: task
            )
            
            assignResult = result
            
        } catch {
            AlertCenter.shared.showError(
                error.localizedDescription
            )
        }
    }
    
        /// Called when the user taps OK on the assign-success alert.
    func dismissAssignSuccessAlert() {
        
            // Optimistic/local state update.
            //
            // This is only a UI synchronization step.
            // The assign API has already succeeded.
        if let task = selectedTaskForApplicants,
           let index = requesterPublishedTasks.firstIndex(
            where: { $0.id == task.id }
           ) {
            requesterPublishedTasks[index].status =
            TaskStatus.inProgress.rawValue
        }
        
        assignResult = nil
        showApplicantsSheet = false
        selectedTaskApplicants = []
        selectedTaskForApplicants = nil
    }
    
        // MARK: - Confirm Task Completion
    
        /// Confirms task completion on the server.
        ///
        /// IMPORTANT:
        /// This action does NOT require the task to exist inside
        /// `requesterPublishedTasks`.
        ///
        /// The list is used only for optimistic UI and rollback.
    func confirmTaskCompletion(_ task: TaskModel) async {
        
            // Find the task only for local optimistic UI.
        let index = requesterPublishedTasks.firstIndex {
            $0.id == task.id
        }
        
            // Save the previous value only if the task exists.
        let previousTask = index.map {
            requesterPublishedTasks[$0]
        }
        
            // Optimistic UI update.
            //
            // Remove it if it happens to be in the published list.
        if let index {
            requesterPublishedTasks.remove(at: index)
        }
        
        do {
                // API ALWAYS runs.
            let result = try await taskRepo.confirmTask(
                id: task.id
            )
            
                // Server confirmation succeeded.
                //
                // Chat deletion is only cleanup. It must never
                // cause the confirmed task to be restored.
            do {
                try await chatRepo.deleteChat(
                    taskId: task.id
                )
            } catch {
                DebugLogger.log(
                    "⚠️ deleteChat failed after confirmTask succeeded | taskId: \(task.id) | error: \(error)"
                )
            }
            
            AlertCenter.shared.show(
                responseType: result.type,
                message: result.message
            )
            
            await notifyExecutorOfConfirmation(
                for: task
            )
            
            await checkPendingRatings()
            
        } catch {
                // Rollback only if the task existed in the list.
            if let index,
               let previousTask {
                requesterPublishedTasks.insert(
                    previousTask,
                    at: min(index, requesterPublishedTasks.count)
                )
            }
            
            AlertCenter.shared.showError(
                error.localizedDescription
            )
        }
    }
    
        // MARK: - Delete Task
    
        /// Deletes a task.
        ///
        /// The API does NOT depend on the task being present
        /// in `requesterPublishedTasks`.
    func deleteTask(_ task: TaskModel) async {
        
            // Find task only for optimistic UI.
        let index = requesterPublishedTasks.firstIndex {
            $0.id == task.id
        }
        
        let removedTask = index.map {
            requesterPublishedTasks[$0]
        }
        
            // Optimistic removal if the task exists locally.
        if let index {
            requesterPublishedTasks.remove(at: index)
        }
        
        do {
                // API ALWAYS runs.
            let result = try await taskRepo.deleteTask(
                id: task.id
            )
            
            AlertCenter.shared.show(
                responseType: result.type,
                message: result.message
            )
            
        } catch {
                // Rollback only if the task existed locally.
            if let index,
               let removedTask {
                requesterPublishedTasks.insert(
                    removedTask,
                    at: min(index, requesterPublishedTasks.count)
                )
            }
            
            AlertCenter.shared.showError(
                error.localizedDescription
            )
        }
    }
    
        // MARK: - Cancel Task
    
        /// Cancels a task.
        ///
        /// The API does NOT depend on the task being present
        /// in `requesterPublishedTasks`.
    func cancelTask(_ task: TaskModel) async {
        
            // Find task only for optimistic UI.
        let index = requesterPublishedTasks.firstIndex {
            $0.id == task.id
        }
        
        let previousTask = index.map {
            requesterPublishedTasks[$0]
        }
        
            // Optimistic update only if task exists locally.
        if let index {
            requesterPublishedTasks[index].status =
            TaskStatus.cancelled.rawValue
        }
        
        do {
                // API ALWAYS runs.
            let result = try await taskRepo.cancelTask(
                id: task.id
            )
            
            AlertCenter.shared.show(
                responseType: result.type,
                message: result.message
            )
            
            await notifyExecutorOfCancellation(
                for: task
            )
            
        } catch {
                // Rollback only if task existed locally.
            if let index,
               let previousTask {
                requesterPublishedTasks[index] = previousTask
            }
            
            AlertCenter.shared.showError(
                error.localizedDescription
            )
        }
    }
    
        // MARK: - Publish Task
    
        /// Publishes a task.
        ///
        /// The API does NOT depend on the task being present
        /// in `requesterPublishedTasks`.
    func publishTask(_ task: TaskModel) async {
        
            // Find task only for optimistic UI.
        let index = requesterPublishedTasks.firstIndex {
            $0.id == task.id
        }
        
        let previousTask = index.map {
            requesterPublishedTasks[$0]
        }
        
            // Optimistic update only if task exists locally.
        if let index {
            requesterPublishedTasks[index].status =
            TaskStatus.published.rawValue
        }
        
        do {
                // API ALWAYS runs.
            let result = try await taskRepo.publishTask(
                id: task.id
            )
            
            AlertCenter.shared.show(
                responseType: result.type,
                message: result.message
            )
            
        } catch {
                // Rollback only if task existed locally.
            if let index,
               let previousTask {
                requesterPublishedTasks[index] = previousTask
            }
            
            AlertCenter.shared.showError(
                error.localizedDescription
            )
        }
    }
    
        // MARK: - Applicants
    
    func showApplicants(for task: TaskModel) async {
        selectedTaskForApplicants = task
        isLoadingApplicants = true
        showApplicantsSheet = true
        
        defer {
            isLoadingApplicants = false
        }
        
        do {
            selectedTaskApplicants = try await taskRepo.getApplicants(
                taskId: task.id
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func declineApplicant(_ applicant: ApplicantModel) async {
        guard let task = selectedTaskForApplicants else {
            return
        }
        
            // Save local state for rollback.
        let previousApplicants = selectedTaskApplicants
        
            // Optimistic removal.
        selectedTaskApplicants.removeAll {
            $0.id == applicant.id
        }
        
        do {
                // API is independent of the local applicant list.
            let result = try await taskRepo.declineApplicant(
                taskId: task.id,
                applicantId: applicant.id
            )
            
            AlertCenter.shared.show(
                responseType: result.type,
                message: result.message
            )
            
            await notifyApplicantOfDecline(
                applicant,
                for: task
            )
            
        } catch {
                // Rollback.
            selectedTaskApplicants = previousApplicants
            
            AlertCenter.shared.showError(
                error.localizedDescription
            )
        }
    }
    
        // MARK: - Filters
    
    func setStatusFilter(
        _ filter: RequesterStatusFilter
    ) {
        statusFilter = filter
        
        Task {
            await loadPublishedTasks()
        }
    }
    
        // MARK: - Published Tasks
    
    func loadPublishedTasks() async {
        isLoading = true
        errorMessage = nil
        
        publishedTasksCursor = nil
        publishedTasksHasMore = true
        publishedTasksGeneration += 1
        
        let myGeneration = publishedTasksGeneration
        
        defer {
            isLoading = false
        }
        
        do {
            let result = try await taskRepo.getRequesterPublishedTasks(
                cursor: nil,
                limit: nil,
                status: statusFilter.apiValue
            )
            
            guard myGeneration == publishedTasksGeneration else {
                return
            }
            
            requesterPublishedTasks = result.tasks
            publishedTasksHasMore = result.hasMore
            publishedTasksCursor = result.cursor
            
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func loadMorePublishedTasksIfNeeded() async {
        guard shouldLoadMore(
            hasMore: publishedTasksHasMore,
            isLoadingMore: isLoadingMorePublishedTasks
        ), !isLoading else {
            return
        }
        
        isLoadingMorePublishedTasks = true
        
        let myGeneration = publishedTasksGeneration
        
        defer {
            isLoadingMorePublishedTasks = false
        }
        
        do {
            let result = try await taskRepo.getRequesterPublishedTasks(
                cursor: publishedTasksCursor,
                limit: nil,
                status: statusFilter.apiValue
            )
            
            guard myGeneration == publishedTasksGeneration else {
                return
            }
            
            requesterPublishedTasks.append(
                contentsOf: result.tasks
            )
            
            publishedTasksHasMore = result.hasMore
            publishedTasksCursor = result.cursor
            
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
        
        defer {
            isLoading = false
        }
        
        do {
            let result = try await taskRepo.getRequesterCompletedTasks(
                cursor: nil,
                limit: nil
            )
            
            guard myGeneration == completedTasksGeneration else {
                return
            }
            
            requesterCompletedTasks = result.tasks
            completedTasksHasMore = result.hasMore
            completedTasksCursor = result.cursor
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
            // Piggyback pending-rating check whenever completed
            // tasks are loaded or reloaded.
        await checkPendingRatings()
    }
    
    func loadMoreCompletedTasksIfNeeded() async {
        guard shouldLoadMore(
            hasMore: completedTasksHasMore,
            isLoadingMore: isLoadingMoreCompletedTasks
        ), !isLoading else {
            return
        }
        
        isLoadingMoreCompletedTasks = true
        
        let myGeneration = completedTasksGeneration
        
        defer {
            isLoadingMoreCompletedTasks = false
        }
        
        do {
            let result = try await taskRepo.getRequesterCompletedTasks(
                cursor: completedTasksCursor,
                limit: nil
            )
            
            guard myGeneration == completedTasksGeneration else {
                return
            }
            
            requesterCompletedTasks.append(
                contentsOf: result.tasks
            )
            
            completedTasksHasMore = result.hasMore
            completedTasksCursor = result.cursor
            
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
        // MARK: - Rating Queue
    
        /// Picks up completed tasks that are still missing
        /// the requester's rating of the executor.
    func checkPendingRatings() async {
        do {
            let result = try await taskRepo.getUnratedRequesterTasks(
                cursor: nil,
                limit: nil
            )
            
            let unrated = result.tasks
            
            for task in unrated
            where !pendingRatingTasks.contains(where: {
                $0.id == task.id
            }) {
                pendingRatingTasks.append(task)
            }
            
            let unratedIds = Set(
                unrated.map(\.id)
            )
            
            pendingRatingTasks.removeAll {
                !unratedIds.contains($0.id)
            }
            
        } catch {
                // Silent failure.
                // Background catch-up check.
        }
    }
    
        /// Called when the rating sheet is dismissed.
    func ratingSheetDismissed(
        for taskId: String,
        wasSubmitted: Bool
    ) {
        if wasSubmitted {
            pendingRatingTasks.removeAll {
                $0.id == taskId
            }
        }
    }
    
        // MARK: - Chat
    
    func openChat(for taskId: String) {
        selectedChatTaskId = taskId
    }
    
        // MARK: - Notifications
    
        /// Notification failures never block or roll back
        /// the task action that triggered them.
    
    private var currentUserDisplayName: String {
        authRepo.currentUser?.displayName ?? "Someone"
    }
    
    private func notifyExecutorOfAssignment(
        _ applicant: ApplicantModel,
        for task: TaskModel
    ) async {
        try? await notificationRepo.send(
            to: applicant.id,
            type: .taskAccepted,
            subjectText: "You're assigned!",
            messageText: "\(currentUserDisplayName) assigned you to \"\(task.title)\"",
            taskId: task.id
        )
    }
    
    private func notifyExecutorOfConfirmation(
        for task: TaskModel
    ) async {
        guard let executorId = task.executor?.id else {
            return
        }
        
        try? await notificationRepo.send(
            to: executorId,
            type: .taskConfirmed,
            subjectText: "Task confirmed!",
            messageText: "\(currentUserDisplayName) confirmed completion of \"\(task.title)\"",
            taskId: task.id
        )
    }
    
    private func notifyApplicantOfDecline(
        _ applicant: ApplicantModel,
        for task: TaskModel
    ) async {
        try? await notificationRepo.send(
            to: applicant.id,
            type: .taskDeclined,
            subjectText: "Application declined",
            messageText: "\(currentUserDisplayName) declined your application for \"\(task.title)\"",
            taskId: task.id
        )
    }
    
        /// Only relevant if the task already had an executor assigned.
    private func notifyExecutorOfCancellation(
        for task: TaskModel
    ) async {
        guard let executorId = task.executor?.id else {
            return
        }
        
        try? await notificationRepo.send(
            to: executorId,
            type: .taskCancelled,
            subjectText: "Task cancelled",
            messageText: "\(currentUserDisplayName) cancelled \"\(task.title)\"",
            taskId: task.id
        )
    }
    
        // MARK: - Helpers
    
    private func shouldLoadMore(
        hasMore: Bool,
        isLoadingMore: Bool
    ) -> Bool {
        hasMore && !isLoadingMore
    }
}
