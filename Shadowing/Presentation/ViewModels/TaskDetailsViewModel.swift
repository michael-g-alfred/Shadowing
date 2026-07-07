import Foundation

@MainActor
@Observable
final class TaskDetailsViewModel {
    
    private let taskRepo: TaskRepositoryProtocol
    let taskId: String
    
    var task: TaskModel?
    var isLoading = false
    var errorMessage: String?
    
    init(taskId: String, taskRepo: TaskRepositoryProtocol) {
        self.taskId = taskId
        self.taskRepo = taskRepo
    }
    
    func loadDetails() async {
        isLoading = true
        errorMessage = nil
        do {
            task = try await taskRepo.getTaskDetails(id: taskId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
