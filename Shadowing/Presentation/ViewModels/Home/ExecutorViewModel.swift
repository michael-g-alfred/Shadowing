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
    
        // MARK: - Apply Confirmation (in-sheet step, not a separate presentation)
        //
        // FIX: this used to be `showFeeConfirmationAlert`, driving a standalone
        // `.alert` in `GlobalSheetsModifier`. That meant `requestApply()` had to
        // close `AppliedSheet` first (`showAppliedSheet = false`) before the alert
        // could show, which in turn meant `acceptTask()` — the thing that actually
        // sets `isApplying = true` and makes the network call — ran after the sheet
        // was already off screen. No loading feedback was ever visible during the
        // real `applyToTask` request.
        //
        // Renamed to `isConfirmingApply`: it now just picks which step
        // `AppliedSheet` shows internally (edit vs. confirm) while the sheet stays
        // open the whole time, including through the network call, so `isApplying`
        // can actually drive a visible overlay.
    private let platformFeeRate: Double = 0.10
    
    var isConfirmingApply = false
    
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
    
        /// Opens `AppliedSheet` on the budget-editing step for `task`.
        ///
        /// Resets any leftover state from a previous, incomplete apply attempt
        /// so a stale error or confirmation step never bleeds into a fresh one.
    func beginApply(to task: TaskModel) {
        selectedTaskForApply = task
        isConfirmingApply = false
        pendingApplyTask = nil
        pendingApplyBudget = nil
        errorMessage = nil
        showAppliedSheet = true
    }
    
        /// Called from `AppliedSheet`'s "Send" button. Switches the sheet from
        /// the edit step to the confirm step — the sheet itself stays open and
        /// on screen the whole time.
    func requestApply(
        to task: TaskModel,
        proposedBudget: Double? = nil
    ) {
        pendingApplyTask = task
        pendingApplyBudget = proposedBudget
        isConfirmingApply = true
    }
    
        /// Called from `AppliedSheet`'s "Back" button on the confirm step.
        /// Returns to the edit step without closing the sheet.
    func cancelApply() {
        isConfirmingApply = false
        pendingApplyTask = nil
        pendingApplyBudget = nil
    }
    
        /// Called from `AppliedSheet`'s "Confirm" button on the confirm step.
    func confirmApply() async {
        guard let task = pendingApplyTask else { return }
        await acceptTask(task, proposedBudget: pendingApplyBudget)
    }
    
        // MARK: - Task Actions
    
    func acceptTask(
        _ task: TaskModel,
        proposedBudget: Double? = nil
    ) async {
        isApplying = true
        errorMessage = nil
        defer { isApplying = false }
        
        let availableUpdate = executorAvailableTasks.updateTask(id: task.id) {
            $0.isApplicant = true
        }
        
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
            
                // Success — safe to close everything now that the request
                // actually landed.
            showAppliedSheet = false
            isConfirmingApply = false
            selectedTaskForApply = nil
            pendingApplyTask = nil
            pendingApplyBudget = nil
            
        } catch {
            executorAvailableTasks.rollbackUpdate(availableUpdate)
            
            errorMessage = error.localizedDescription
            AlertCenter.shared.showError(
                error.localizedDescription
            )
                // Failure — stay open on the confirm step so the user can see
                // the error and either retry Confirm or tap Back to edit again.
                // `pendingApplyTask`/`pendingApplyBudget` are deliberately left
                // intact for that retry.
        }
    }
    
    func withdrawFromTask(_ task: TaskModel) async {
        // An assigned executor (working, or still waiting for the requester's
        // payment) lives in the "assigned" list; only a plain applicant lives
        // in "available".
        let wasAssigned = (
            task.status == TaskStatus.inProgress.rawValue
            || task.status == TaskStatus.pendingPayment.rawValue
        )
        
        let assignedRemoval: (index: Int, task: TaskModel)?
        let availableUpdate: (index: Int, task: TaskModel)?
        
        if wasAssigned {
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
            
            if wasAssigned {
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
    
        /// - Parameter showLoadingIndicator: When `true` (the default), sets
        ///   `isLoading`, which `TaskListView` uses to swap in the full-screen
        ///   skeleton. Pass `false` for a pull-to-refresh call — flipping
        ///   `isLoading` mid-refresh replaces the still-visible `List` (and
        ///   the `.refreshable`-owned task riding on it) with the skeleton
        ///   view, cancelling the in-flight request ("Request failed:
        ///   cancelled"). With `false`, the `List` and its native refresh
        ///   spinner stay put for the whole call.
    func loadAvailableTasks(showLoadingIndicator: Bool = true) async {
        if showLoadingIndicator {
            isLoading = true
        }
        errorMessage = nil
        
        availableTasksCursor = nil
        availableTasksHasMore = true
        availableTasksGeneration += 1
        
        let myGeneration = availableTasksGeneration
        
        defer {
            if showLoadingIndicator {
                isLoading = false
            }
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
    
        /// See `loadAvailableTasks(showLoadingIndicator:)` for why this takes
        /// the same parameter.
    func loadAssignedTasks(showLoadingIndicator: Bool = true) async {
        if showLoadingIndicator {
            isLoading = true
        }
        errorMessage = nil
        
        assignedTasksCursor = nil
        assignedTasksHasMore = true
        assignedTasksGeneration += 1
        
        let myGeneration = assignedTasksGeneration
        
        defer {
            if showLoadingIndicator {
                isLoading = false
            }
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
    
        /// See `loadAvailableTasks(showLoadingIndicator:)` for why this takes
        /// the same parameter.
    func loadCompletedTasks(showLoadingIndicator: Bool = true) async {
        if showLoadingIndicator {
            isLoading = true
        }
        errorMessage = nil
        
        completedTasksCursor = nil
        completedTasksHasMore = true
        completedTasksGeneration += 1
        
        let myGeneration = completedTasksGeneration
        
        defer {
            if showLoadingIndicator {
                isLoading = false
            }
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
