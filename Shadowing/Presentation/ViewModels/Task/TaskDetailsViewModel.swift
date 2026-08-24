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

        /// Mirrors the executor apply flow — the "apply" sheet plus the
        /// following fee-confirmation alert — so the details screen can refresh
        /// once the whole flow finishes (applied or cancelled). Stays `true`
        /// across the sheet→alert hand-off and only becomes `false` when the
        /// flow has fully ended.
    var isApplyFlowPresented: Bool {
        executorVM.showAppliedSheet || executorVM.showFeeConfirmationAlert
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
