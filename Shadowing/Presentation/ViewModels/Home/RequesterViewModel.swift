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
    
    private var completedTasksCursor: String?
    private var completedTasksHasMore = true
    
    var showAddTaskSheet: Bool = false
    var showRateExecutorSheet: Bool = false
    var executorName: String?
    var selectedTaskIdForRating: String?
    
        // Applicants sheet state
    var showApplicantsSheet: Bool = false
    var selectedTaskApplicants: [ApplicantModel] = []
    var isLoadingApplicants = false
    var selectedTaskForApplicants: TaskModel?
    var isAssigningExecutor = false
    
    var selectedTaskId: String?
    
//        // Payment sheet state
//    var showPaymentSheet: Bool = false
//    var paymentURL: URL?
//    var paymentTaskId: String?
    
    private let repository: TaskRepositoryProtocol
    private let chatRepo: ChatRepositoryProtocol
    
    init(repository: TaskRepositoryProtocol, chatRepo: ChatRepositoryProtocol) {
        self.repository = repository
        self.chatRepo = chatRepo
        DebugLogger.log("🚀 RequesterViewModel initialized")
    }
    
    func select(_ tab: RequesterTab) {
        selectedTab = tab
        DebugLogger.log("🚀 RequesterViewModel initialized")
    }
    
        // MARK: - Task Actions
    
    func deleteTask(_ task: TaskModel) async {
        do {
            try await repository.deleteTask(id: task.id)
            requesterPublishedTasks.removeAll { $0.id == task.id }
            DebugLogger.log("✅ Task \(task.id) deleted locally")
        } catch {
            errorMessage = error.localizedDescription
            DebugLogger.log("❌ Failed to delete task \(task.id): \(error.localizedDescription)")
        }
    }
    
    func cancelTask(_ task: TaskModel) async {
        do {
            try await repository.cancelTask(id: task.id)
            await loadPublishedTasks()
            DebugLogger.log("✅ Task \(task.id) cancelled")
        } catch {
            errorMessage = error.localizedDescription
            DebugLogger.log("❌ Failed to cancel task \(task.id): \(error.localizedDescription)")
        }
    }
    
    func publishTask (_ task: TaskModel) async {
        do {
            try await repository.publishTask(id: task.id)
            await loadPublishedTasks()
            DebugLogger.log("✅ Task \(task.id) Published")
        } catch {
            errorMessage = error.localizedDescription
            DebugLogger.log("❌ Failed to cancel task \(task.id): \(error.localizedDescription)")
        }
    }
    
    func confirmTaskCompletion(_ task: TaskModel) async {
        do {
            try await repository.confirmTask(id: task.id)
            
                // Chat lifecycle: conversation is deleted once the task is
                // confirmed as completed by the requester.
            try? await chatRepo.deleteConversation(taskId: task.id)
            
            requesterPublishedTasks.removeAll { $0.id == task.id }
            DebugLogger.log("✅ Task \(task.id) confirmed as completed")
            
            selectedTaskIdForRating = task.id
            executorName = task.executor?.displayName
            showRateExecutorSheet = true
        } catch {
            errorMessage = error.localizedDescription
            DebugLogger.log("❌ Failed to confirm task \(task.id): \(error.localizedDescription)")
        }
    }
    
    func showApplicants(for task: TaskModel) async {
        selectedTaskForApplicants = task
        isLoadingApplicants = true
        showApplicantsSheet = true
        defer { isLoadingApplicants = false }
        
        do {
            selectedTaskApplicants = try await repository.getApplicants(taskId: task.id)
            DebugLogger.log("✅ Loaded \(selectedTaskApplicants.count) applicants for task \(task.id)")
        } catch {
            errorMessage = error.localizedDescription
            DebugLogger.log("❌ Failed to load applicants for task \(task.id): \(error.localizedDescription)")
        }
    }
    
    func assignExecutor(_ applicant: ApplicantModel) async {
        guard let task = selectedTaskForApplicants else { return }
        isAssigningExecutor = true
        defer { isAssigningExecutor = false }
        
        do {
            try await repository.assignExecutor(taskId: task.id, executorId: applicant.id)
//            let url = try await repository.assignExecutor(taskId: task.id, executorId: applicant.id)
            DebugLogger.log("✅ Assigned executor \(applicant.id) to task \(task.id)")
            
                // Chat lifecycle: create the Firestore conversation now that the
                // task has moved to inProgress. We build the executor's
                // TaskUserModel from the applicant since `task.executor` is
                // still nil at this point (task hasn't been re-fetched yet).
            let executorProfile = TaskUserModel(
                id: applicant.id,
                displayName: applicant.displayName,
                avatarUrl: applicant.avatarUrl,
                rating: applicant.rating ?? 0,
                totalRatings: 0,
                completedTasks: applicant.completedTasks
            )
            try? await chatRepo.ensureConversationExists(
                taskId: task.id,
                taskTitle: task.title,
                requester: task.requester,
                executor: executorProfile
            )
            
            showApplicantsSheet = false
            selectedTaskApplicants = []
            selectedTaskForApplicants = nil
            
//            paymentURL = url
//            paymentTaskId = task.id
//            showPaymentSheet = true
            
            await loadPublishedTasks()
        } catch {
            errorMessage = error.localizedDescription
            DebugLogger.log("❌ Failed to assign executor \(applicant.id) to task \(task.id): \(error.localizedDescription)")
        }
    }
    
        /// Called when the payment sheet (WebView) is dismissed, either because
        /// the user finished paying or cancelled. We just refresh the task list
        /// — the backend webhook is the source of truth for escrow state.
//    func paymentSheetDismissed() async {
//        showPaymentSheet = false
//        paymentURL = nil
//        paymentTaskId = nil
//        await loadPublishedTasks()
//    }
    
        /// For a task that's assigned but payment failed/was abandoned
        /// (escrowStatus still .notPaid). Lets the requester retry from
        /// the published tasks list.
//    func retryPayment(for task: TaskModel) async {
//        do {
//            let url = try await repository.retryPayment(taskId: task.id)
//            paymentURL = url
//            paymentTaskId = task.id
//            showPaymentSheet = true
//        } catch {
//            errorMessage = error.localizedDescription
//            DebugLogger.log("❌ Failed to retry payment for task \(task.id): \(error.localizedDescription)")
//        }
//    }
    
    func declineApplicant(_ applicant: ApplicantModel) async {
        guard let task = selectedTaskForApplicants else { return }
        
        do {
            try await repository.declineApplicant(taskId: task.id, applicantId: applicant.id)
            selectedTaskApplicants.removeAll { $0.id == applicant.id }
            DebugLogger.log("✅ Declined applicant \(applicant.id) for task \(task.id)")
        } catch {
            errorMessage = error.localizedDescription
            DebugLogger.log("❌ Failed to decline applicant \(applicant.id) for task \(task.id): \(error.localizedDescription)")
        }
    }
    
        // MARK: - Published Tasks
    
    func loadPublishedTasks() async {
        DebugLogger.log("══════════════════════════════════════")
        DebugLogger.log("📤 Loading Requester Published Tasks...")
        
        isLoading = true
        errorMessage = nil
        publishedTasksCursor = nil
        publishedTasksHasMore = true
        
        defer {
            isLoading = false
            DebugLogger.log("⏹️ Loading Finished")
            DebugLogger.log("══════════════════════════════════════")
        }
        
        do {
            let result = try await repository.getRequesterPublishedTasks(cursor: nil, limit: nil)
            requesterPublishedTasks = result.tasks
            publishedTasksHasMore = result.hasMore
            publishedTasksCursor = result.cursor
            
            DebugLogger.log("✅ Published Tasks Loaded")
            DebugLogger.log("📋 Tasks Count: \(requesterPublishedTasks.count), hasMore: \(publishedTasksHasMore)")
        } catch {
            errorMessage = error.localizedDescription
            
            DebugLogger.log("❌ Failed to Load Published Tasks")
            DebugLogger.log("🚨 Error: \(error.localizedDescription)")
        }
    }
    
    func loadMorePublishedTasksIfNeeded() async {
        guard shouldLoadMore(
            hasMore: publishedTasksHasMore,
            isLoadingMore: isLoadingMorePublishedTasks
        ) else { return }
        
        DebugLogger.log("📤 Loading more Requester Published Tasks (cursor: \(publishedTasksCursor ?? "nil"))")
        
        isLoadingMorePublishedTasks = true
        defer { isLoadingMorePublishedTasks = false }
        
        do {
            let result = try await repository.getRequesterPublishedTasks(cursor: publishedTasksCursor, limit: nil)
            requesterPublishedTasks.append(contentsOf: result.tasks)
            publishedTasksHasMore = result.hasMore
            publishedTasksCursor = result.cursor
            
            DebugLogger.log("✅ More Published Tasks Loaded. Total: \(requesterPublishedTasks.count)")
        } catch {
            errorMessage = error.localizedDescription
            DebugLogger.log("❌ Failed to Load More Published Tasks: \(error.localizedDescription)")
        }
    }
    
        // MARK: - Completed Tasks
    
    func loadCompletedTasks() async {
        DebugLogger.log("══════════════════════════════════════")
        DebugLogger.log("✅ Loading Requester Completed Tasks...")
        
        isLoading = true
        errorMessage = nil
        completedTasksCursor = nil
        completedTasksHasMore = true
        
        defer {
            isLoading = false
            DebugLogger.log("⏹️ Loading Finished")
            DebugLogger.log("══════════════════════════════════════")
        }
        
        do {
            let result = try await repository.getRequesterCompletedTasks(cursor: nil, limit: nil)
            requesterCompletedTasks = result.tasks
            completedTasksHasMore = result.hasMore
            completedTasksCursor = result.cursor
            
            DebugLogger.log("✅ Completed Tasks Loaded")
            DebugLogger.log("📋 Tasks Count: \(requesterCompletedTasks.count), hasMore: \(completedTasksHasMore)")
        } catch {
            errorMessage = error.localizedDescription
            
            DebugLogger.log("❌ Failed to Load Completed Tasks")
            DebugLogger.log("🚨 Error: \(error.localizedDescription)")
        }
    }
    
    func loadMoreCompletedTasksIfNeeded() async {
        guard shouldLoadMore(
            hasMore: completedTasksHasMore,
            isLoadingMore: isLoadingMoreCompletedTasks
        ) else { return }
        
        DebugLogger.log("✅ Loading more Requester Completed Tasks (cursor: \(completedTasksCursor ?? "nil"))")
        
        isLoadingMoreCompletedTasks = true
        defer { isLoadingMoreCompletedTasks = false }
        
        do {
            let result = try await repository.getRequesterCompletedTasks(cursor: completedTasksCursor, limit: nil)
            requesterCompletedTasks.append(contentsOf: result.tasks)
            completedTasksHasMore = result.hasMore
            completedTasksCursor = result.cursor
            
            DebugLogger.log("✅ More Completed Tasks Loaded. Total: \(requesterCompletedTasks.count)")
        } catch {
            errorMessage = error.localizedDescription
            DebugLogger.log("❌ Failed to Load More Completed Tasks: \(error.localizedDescription)")
        }
    }
    
        // MARK: - Helpers
    
        /// Triggers when the visible row is within the last 5 items of the current list.
    private func shouldLoadMore(hasMore: Bool, isLoadingMore: Bool) -> Bool {
        return hasMore && !isLoadingMore
    }
}
