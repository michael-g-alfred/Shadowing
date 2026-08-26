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
    
        /// Controls presentation of the search bar
    var isSearchPresented = false
    
        /// Optional case-insensitive title/description filter for available tasks
    var searchText = ""
    
    private var assignedTasksCursor: String?
    private var assignedTasksHasMore = true
    private var assignedTasksGeneration = 0
    
    private var completedTasksCursor: String?
    private var completedTasksHasMore = true
    private var completedTasksGeneration = 0
    
    private let taskRepo: TaskRepositoryProtocol
    private let chatRepo: ChatRepositoryProtocol
    private let notificationRepo: NotificationRepositoryProtocol
    private let authRepo: AuthRepositoryProtocol
    
        // MARK: - Applied Sheet
    
    var showAppliedSheet = false
    var selectedTaskForApply: TaskModel?
    var isApplying = false
    
        // MARK: - Fee Confirmation Alert
    
    private let platformFeeRate: Double = 0.10
    
    var showFeeConfirmationAlert = false
    
    private var pendingApplyTask: TaskModel?
    private var pendingApplyBudget: Double?
    
    var feeConfirmationGrossAmount: Double {
        pendingApplyBudget ?? pendingApplyTask?.budget ?? 0
    }
    
    var feeConfirmationNetAmount: Double {
        feeConfirmationGrossAmount * (1 - platformFeeRate)
    }
    
    var feeConfirmationMessage: LocalizedStringResource {
        let gross = formattedCurrency(feeConfirmationGrossAmount)
        let net = formattedCurrency(feeConfirmationNetAmount)
        
        return "A 10% fee will be deducted from the offered amount (\(gross)). You'll actually receive \(net)."
    }
    
    private func formattedCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        
        return formatter.string(
            from: NSNumber(value: value)
        ) ?? String(format: "%.2f", value)
    }
    
        // MARK: - Rating Queue
    
    private(set) var pendingRatingTasks: [TaskModel] = []
    
    var currentRatingTask: TaskModel? {
        pendingRatingTasks.first
    }
    
    var selectedTaskId: String?
    var selectedChatTaskId: String?
    
        // MARK: - Init
    
    init(
        authRepo: AuthRepositoryProtocol,
        taskRepo: TaskRepositoryProtocol,
        chatRepo: ChatRepositoryProtocol,
        notificationRepo: NotificationRepositoryProtocol
    ) {
        self.taskRepo = taskRepo
        self.chatRepo = chatRepo
        self.notificationRepo = notificationRepo
        self.authRepo = authRepo
    }
    
        // MARK: - Navigation
    
    func select(_ tab: ExecutorTab) {
        selectedTab = tab
    }
    
        // MARK: - Apply
    
    func beginApply(to task: TaskModel) {
        selectedTaskForApply = task
        showAppliedSheet = true
    }
    
    func requestApply(
        to task: TaskModel,
        proposedBudget: Double? = nil
    ) {
        pendingApplyTask = task
        pendingApplyBudget = proposedBudget
        
        showAppliedSheet = false
        showFeeConfirmationAlert = true
    }
    
    func confirmApply() async {
        guard let task = pendingApplyTask else { return }
        
        let budget = pendingApplyBudget
        
        showFeeConfirmationAlert = false
        pendingApplyTask = nil
        pendingApplyBudget = nil
        
        await acceptTask(
            task,
            proposedBudget: budget
        )
    }
    
    func cancelApply() {
        showFeeConfirmationAlert = false
        pendingApplyTask = nil
        pendingApplyBudget = nil
    }
    
        // MARK: - Task Actions
    
    func acceptTask(
        _ task: TaskModel,
        proposedBudget: Double? = nil
    ) async {
        isApplying = true
        defer { isApplying = false }
        
        let availableUpdate = executorAvailableTasks.updateTask(id: task.id) {
            $0.isApplicant = true
        }
        
        showAppliedSheet = false
        selectedTaskForApply = nil
        
        do {
            let result = try await taskRepo.applyToTask(
                id: task.id,
                proposedBudget: proposedBudget
            )
            
            AlertCenter.shared.show(
                responseType: result.type,
                message: result.message
            )
            
            await notifyRequesterOfApplication(
                for: task
            )
            
        } catch {
            executorAvailableTasks.rollbackUpdate(availableUpdate)
            
            AlertCenter.shared.showError(
                error.localizedDescription
            )
        }
    }
    
    func withdrawFromTask(_ task: TaskModel) async {
        let wasInProgress = (
            task.status == TaskStatus.inProgress.rawValue
        )
        
        let assignedRemoval: (index: Int, task: TaskModel)?
        let availableUpdate: (index: Int, task: TaskModel)?
        
        if wasInProgress {
            assignedRemoval = executorAssignedTasks.removeTask(id: task.id)
            availableUpdate = nil
        } else {
            assignedRemoval = nil
            availableUpdate = executorAvailableTasks.updateTask(id: task.id) {
                $0.isApplicant = false
            }
        }
        
        do {
            let result = try await taskRepo.withdrawFromTask(
                id: task.id
            )
            
            if let warning = result.warning {
                AlertCenter.shared.show(
                    responseType: result.type,
                    message: warning
                )
            } else {
                AlertCenter.shared.show(
                    responseType: result.type,
                    message: result.message
                )
            }
            
            if wasInProgress {
                try? await chatRepo.deleteChat(
                    taskId: task.id
                )
            }
            
            await notifyRequesterOfWithdrawal(
                from: task
            )
            
        } catch {
            executorAssignedTasks.rollbackRemoval(assignedRemoval)
            executorAvailableTasks.rollbackUpdate(availableUpdate)
            
            AlertCenter.shared.showError(
                error.localizedDescription
            )
        }
    }
    
    func markTaskDone(_ task: TaskModel) async {
        
        let assignedUpdate = executorAssignedTasks.updateTask(id: task.id) {
            $0.status = TaskStatus.pendingCompleted.rawValue
        }
        
        do {
            let result = try await taskRepo.markTaskDone(
                id: task.id
            )
            
            AlertCenter.shared.show(
                responseType: result.type,
                message: result.message
            )
            
            await notifyRequesterOfMarkDone(
                for: task
            )
            
        } catch {
            executorAssignedTasks.rollbackUpdate(assignedUpdate)
            
            AlertCenter.shared.showError(
                error.localizedDescription
            )
        }
    }
    
        // MARK: - Favorites
    
    func toggleFavorite(_ task: TaskModel) async {
        let newValue = !task.isFavorite
        
        setFavorite(
            newValue,
            forTaskId: task.id
        )
        
        do {
            let result: (
                message: String,
                type: String
            )
            
            if newValue {
                result = try await taskRepo.favoriteTask(
                    id: task.id
                )
            } else {
                result = try await taskRepo.unfavoriteTask(
                    id: task.id
                )
            }
            
            if showFavoritesOnly && !newValue {
                executorAvailableTasks.removeAll {
                    $0.id == task.id
                }
            }
            
            AlertCenter.shared.show(
                responseType: result.type,
                message: result.message
            )
            
        } catch {
            setFavorite(
                !newValue,
                forTaskId: task.id
            )
            
            AlertCenter.shared.showError(
                error.localizedDescription
            )
        }
    }
    
    private func setFavorite(
        _ isFavorite: Bool,
        forTaskId taskId: String
    ) {
        _ = executorAvailableTasks.updateTask(id: taskId) {
            $0.isFavorite = isFavorite
        }
    }
    
        // MARK: - Rating Queue
    
    func checkPendingRatings() async {
        do {
            let result = try await taskRepo.getPendingRatingsForExecutor(
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
        }
    }
    
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
    
        // MARK: - Available Tasks
    
    func loadAvailableTasks() async {
        isLoading = true
        errorMessage = nil
        
        availableTasksCursor = nil
        availableTasksHasMore = true
        availableTasksGeneration += 1
        
        let myGeneration = availableTasksGeneration
        
        defer {
            isLoading = false
        }
        
        do {
            let result = try await taskRepo.getExecutorAvailableTasks(
                cursor: nil,
                limit: nil,
                favoritesOnly: showFavoritesOnly,
                search: searchText.isEmpty ? nil : searchText
            )
            
            guard myGeneration == availableTasksGeneration else {
                return
            }
            
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
        ), !isLoading else {
            return
        }
        
        isLoadingMoreAvailableTasks = true
        
        let myGeneration = availableTasksGeneration
        
        defer {
            isLoadingMoreAvailableTasks = false
        }
        
        do {
            let result = try await taskRepo.getExecutorAvailableTasks(
                cursor: availableTasksCursor,
                limit: nil,
                favoritesOnly: showFavoritesOnly,
                search: searchText.isEmpty ? nil : searchText
            )
            
            guard myGeneration == availableTasksGeneration else {
                return
            }
            
            executorAvailableTasks.append(
                contentsOf: result.tasks
            )
            
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
        
        defer {
            isLoading = false
        }
        
        do {
            let result = try await taskRepo.getExecutorAssignedTasks(
                cursor: nil,
                limit: nil
            )
            
            guard myGeneration == assignedTasksGeneration else {
                return
            }
            
            executorAssignedTasks = result.tasks
            assignedTasksHasMore = result.hasMore
            assignedTasksCursor = result.cursor
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        await checkPendingRatings()
    }
    
    func loadMoreAssignedTasksIfNeeded() async {
        guard shouldLoadMore(
            hasMore: assignedTasksHasMore,
            isLoadingMore: isLoadingMoreAssignedTasks
        ), !isLoading else {
            return
        }
        
        isLoadingMoreAssignedTasks = true
        
        let myGeneration = assignedTasksGeneration
        
        defer {
            isLoadingMoreAssignedTasks = false
        }
        
        do {
            let result = try await taskRepo.getExecutorAssignedTasks(
                cursor: assignedTasksCursor,
                limit: nil
            )
            
            guard myGeneration == assignedTasksGeneration else {
                return
            }
            
            executorAssignedTasks.append(
                contentsOf: result.tasks
            )
            
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
        
        defer {
            isLoading = false
        }
        
        do {
            let result = try await taskRepo.getExecutorCompletedTasks(
                cursor: nil,
                limit: nil
            )
            
            guard myGeneration == completedTasksGeneration else {
                return
            }
            
            executorCompletedTasks = result.tasks
            completedTasksHasMore = result.hasMore
            completedTasksCursor = result.cursor
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
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
            let result = try await taskRepo.getExecutorCompletedTasks(
                cursor: completedTasksCursor,
                limit: nil
            )
            
            guard myGeneration == completedTasksGeneration else {
                return
            }
            
            executorCompletedTasks.append(
                contentsOf: result.tasks
            )
            
            completedTasksHasMore = result.hasMore
            completedTasksCursor = result.cursor
            
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
        // MARK: - Chat
    
    func openChat(for taskId: String) {
        selectedChatTaskId = taskId
    }
    
        // MARK: - Notifications
    
    private var currentUserDisplayName: String {
        authRepo.currentUser?.displayName ?? "Someone"
    }
    
    private func notifyRequesterOfApplication(
        for task: TaskModel
    ) async {
        try? await notificationRepo.send(
            to: task.requester.id,
            type: .taskApplied,
            subjectText: "New applicant",
            messageText: "\(currentUserDisplayName) applied to your task \"\(task.title)\"",
            taskId: task.id
        )
    }
    
    private func notifyRequesterOfWithdrawal(
        from task: TaskModel
    ) async {
        try? await notificationRepo.send(
            to: task.requester.id,
            type: .taskWithdrawn,
            subjectText: "Executor withdrew",
            messageText: "\(currentUserDisplayName) withdrew from your task \"\(task.title)\"",
            taskId: task.id
        )
    }
    
    private func notifyRequesterOfMarkDone(
        for task: TaskModel
    ) async {
        try? await notificationRepo.send(
            to: task.requester.id,
            type: .taskCompleted,
            subjectText: "Task marked as done",
            messageText: "\(currentUserDisplayName) marked \"\(task.title)\" as done — please confirm completion",
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
