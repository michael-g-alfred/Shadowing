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
        return isRequesterTask ? requesterActions(for: task) : executorActions(for: task)
    }
    
    private func requesterActions(for task: TaskModel) -> [TaskDetailAction] {
        var actions: [TaskDetailAction] = []
        
        if task.status == TaskStatus.published.rawValue || task.status == TaskStatus.pending.rawValue {
            actions.append(.applicants)
        }
        if task.status == TaskStatus.pendingCompleted.rawValue {
            actions.append(.confirmCompletion)
        }
        if task.status == TaskStatus.inProgress.rawValue || task.status == TaskStatus.pendingCompleted.rawValue {
            actions.append(.chats)
        }
        if task.status == TaskStatus.published.rawValue || task.status == TaskStatus.pending.rawValue {
            actions.append(.cancel)
        }
        if task.status == TaskStatus.cancelled.rawValue {
            actions.append(.publish)
        }
        if task.status == TaskStatus.published.rawValue
            || task.status == TaskStatus.pending.rawValue
            || task.status == TaskStatus.cancelled.rawValue {
            actions.append(.delete)
        }
        return actions
    }
    
    private func executorActions(for task: TaskModel) -> [TaskDetailAction] {
        var actions: [TaskDetailAction] = []
        
        if (task.status == TaskStatus.published.rawValue || task.status == TaskStatus.pending.rawValue) {
            if task.isApplicant {
                actions.append(.withdraw)
            } else {
                actions.append(.accept)
            }
        }
        if task.status == TaskStatus.inProgress.rawValue {
            actions.append(.markDone)
            actions.append(.chats)
            actions.append(.withdraw)
        }
        if task.status == TaskStatus.pendingCompleted.rawValue {
            actions.append(.chats)
        }
        return actions
    }
    
        // MARK: - Perform
    
    func perform(_ action: TaskDetailAction) async {
        guard let task else { return }
        switch action {
            case .applicants:
                await requesterVM.showApplicants(for: task)
            case .confirmCompletion:
                await requesterVM.confirmTaskCompletion(task)
            case .chats:
                if isRequesterTask {
                    requesterVM.openChat(for: task.id)
                } else {
                    executorVM.openChat(for: task.id)
                }
            case .delete:
                await requesterVM.deleteTask(task)
            case .cancel:
                await requesterVM.cancelTask(task)
            case .publish:
                await requesterVM.publishTask(task)
            case .accept:
                executorVM.beginApply(to: task)
            case .withdraw:
                await executorVM.withdrawFromTask(task)
            case .markDone:
                await executorVM.markTaskDone(task)
        }
    }
}
