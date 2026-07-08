import Foundation

protocol TaskRepositoryProtocol {
    
        // MARK: - Shared
    
    func getAllTasks(cursor: String?, limit: Int?) async throws -> PaginatedTasksResult
    func getTaskDetails(id: String) async throws -> TaskModel
    
        // MARK: - Map
    
    func getMapTasks(bounds: MapBounds) async throws -> MapTasksPage
    
        // MARK: - Requester
    
    func postTask( title: String, description: String, budget: Double, priority: TaskPriority, serviceType: String, address: String, latitude: Double?, longitude: Double?, scheduledAt: Date?, preferredTimeOfDay: PreferredTimeOfDay? ) async throws -> TaskModel
    
    func getRequesterPublishedTasks(cursor: String?, limit: Int?) async throws -> PaginatedTasksResult
    func getRequesterCompletedTasks(cursor: String?, limit: Int?) async throws -> PaginatedTasksResult
    
        // MARK: - Executor
    
    func getExecutorAvailableTasks(cursor: String?, limit: Int?) async throws -> PaginatedTasksResult
    func getExecutorAssignedTasks(cursor: String?, limit: Int?) async throws -> PaginatedTasksResult
    func getExecutorCompletedTasks(cursor: String?, limit: Int?) async throws -> PaginatedTasksResult
    
        // MARK: - Requester Actions
    
    func deleteTask(id: String) async throws
    func cancelTask(id: String) async throws
    func publishTask(id: String) async throws
    func confirmTask(id: String) async throws
    func getApplicants(taskId: String) async throws -> [ApplicantModel]
    func assignExecutor(taskId: String, executorId: String) async throws
    func declineApplicant(taskId: String, applicantId: String) async throws
    
        // MARK: - Executor Actions
    
    func applyToTask(id: String, proposedBudget: Double?) async throws
    func withdrawFromTask(id: String) async throws
    func markTaskDone(id: String) async throws
    
        // MARK: - Rating Actions
    func rateExecutor(taskId: String, rating: Int, comment: String) async throws
    func rateRequester(taskId: String, rating: Int, comment: String) async throws

}
