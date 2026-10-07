import Foundation
import SwiftUI

@MainActor
@Observable
final class TaskDetailsViewModel {
    
    private let taskRepo: TaskRepositoryProtocol
    private let requesterVM: RequesterViewModel
    private let executorVM: ExecutorViewModel
    private let authRepo: AuthRepositoryProtocol
    
    let taskId: String
    
    var task: TaskModel?
    var reqUser: UserSummaryModel?
    var exeUser: UserSummaryModel?
    
    var isLoading = false
    var errorMessage: String?
    
    var selectedUserForRatings: UserSummaryModel?
    
    init(
        taskId: String,
        taskRepo: TaskRepositoryProtocol,
        requesterVM: RequesterViewModel,
        executorVM: ExecutorViewModel,
        authRepo: AuthRepositoryProtocol
    ) {
        self.taskId = taskId
        self.taskRepo = taskRepo
        self.requesterVM = requesterVM
        self.executorVM = executorVM
        self.authRepo = authRepo
    }
    
    func loadDetails() async {
        isLoading = true
        errorMessage = nil
        do {
            task = try await taskRepo.getTaskDetails(id: taskId)
            reqUser = task?.requester
            exeUser = task?.executor
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
        // MARK: - Role
    
    private var currentUserId: String? {
        authRepo.currentUser?.id
    }
    
    var isRequesterTask: Bool {
        guard let task else { return false }
        return task.requester.id == currentUserId
    }
    
        // MARK: - Applicants Sheet Bridge
    
        /// Mirrors the shared requester view model's applicants-sheet state so
        /// the details screen can refresh itself once the sheet closes (e.g.
        /// after an executor is assigned or an applicant is declined). The
        /// assign/decline actions run against the shared `requesterVM` inside
        /// the sheet, so the details screen otherwise has no way to know its
        /// task changed.
    var isApplicantsSheetPresented: Bool {
        requesterVM.showApplicantsSheet
    }
    
        /// Mirrors the executor apply flow (`AppliedSheet`, covering both the
        /// budget-edit and fee-confirmation steps internally) so the details
        /// screen can refresh once the flow finishes (applied or cancelled).
        ///
        /// Used to also OR in `executorVM.showFeeConfirmationAlert`, back
        /// when confirming the fee was a separate `.alert` that only opened
        /// after `AppliedSheet` had already closed — this property bridged
        /// that gap. The confirmation step now lives inside `AppliedSheet`
        /// itself (`executorVM.isConfirmingApply`) instead of a separate
        /// presentation, so `showAppliedSheet` alone covers the whole flow
        /// and there's no gap left to bridge.
    var isApplyFlowPresented: Bool {
        executorVM.showAppliedSheet
    }
    
        // MARK: - Payment
    
        /// Drives the payment sheet directly from this screen (unlike the
        /// applicants/apply flows above, payment has no shared view model to
        /// bridge to — `PaymentViewModel` is created fresh per attempt, so
        /// `TaskDetailsView` owns this flag and presents it itself).
    var isPaymentSheetPresented = false
    
        /// Call from the "Pay Now" action. `TaskDetailsView` presents the
        /// payment sheet from `isPaymentSheetPresented` and refreshes `task`
        /// via `loadDetails()` once it closes — the same
        /// present-a-flag/`.onChange`-to-refresh pattern already used for the
        /// applicants sheet and apply flow above.
    func startPayment() {
        isPaymentSheetPresented = true
    }
    
        /// Call once the payment sheet closes. Asks the server to re-check the
        /// payment with Paymob first (so a late webhook doesn't leave the task
        /// showing `pending_payment`) and notifies the executor if it went
        /// through, then reloads the details.
    func paymentSheetDismissed() async {
        await requesterVM.settlePayment(taskId: taskId)
        await loadDetails()
    }
    
        /// Call after a refresh that followed the applicants sheet closing.
        /// If `task` just became `in_progress` with escrow still `not_paid` —
        /// i.e. an executor was just assigned — opens the payment sheet
        /// immediately rather than leaving the requester to find the Pay Now
        /// action themselves. A no-op otherwise: an applicant was declined,
        /// the sheet was dismissed without assigning anyone, or the task was
        /// already paid.
        ///
        /// NOTE: this only fires for an assign that happens while this
        /// screen's applicants sheet is open. If your app can also assign an
        /// executor from elsewhere (e.g. a swipe action on a task list, sight
        /// unseen from `TaskDetailsView`), that path needs the same hook
        /// wired in wherever *that* assign flow lives too — this alone won't
        /// cover it.
    func startPaymentIfJustAssigned() {
        guard let task,
              task.status == TaskStatus.pendingPayment.rawValue,
              task.escrowStatus == "not_paid"
        else { return }
        startPayment()
    }
    
        // MARK: - Available Actions
    
    var availableActions: [TaskDetailAction] {
        guard let task else { return [] }
        return isRequesterTask
        ? TaskDetailAction.requesterActions(for: task)
        : TaskDetailAction.executorActions(for: task)
    }
    
        // MARK: - Perform
    
    func perform(_ action: TaskDetailAction) async {
        guard let task else { return }
        if isRequesterTask {
            await requesterSwipePerform(action, task: task, vm: requesterVM)
        } else {
            await executorSwipePerform(action, task: task, vm: executorVM)
        }
    }
}
