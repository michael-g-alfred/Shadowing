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
