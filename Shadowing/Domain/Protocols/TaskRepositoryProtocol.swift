import Foundation

protocol TaskRepositoryProtocol {
    
        // MARK: - Shared
    
    func getAllTasks(cursor: String?, limit: Int?) async throws -> PaginatedTasksResult
    func getTaskDetails(id: String) async throws -> TaskModel
    
        // MARK: - Map
    
    func getMapTasks(bounds: MapBounds) async throws -> MapTasksPage
    
        // MARK: - Requester
    
    // NOTE: signature changed —
    //   - added `currencyId: Int` (was missing entirely; the amount/currency
    //     picker were never separable before)
    //   - `serviceType: String` -> `serviceTypeId: Int` (backend now stores
    //     tasks.service_type_id, an FK to task_services.id, instead of a
    //     name string)
    //   - `priorityId: Int` stays an Int as before, but now matches the
    //     backend's task.schema.js "priorityId" field name exactly (it
    //     previously sent this shape but the backend expected a "priority"
    //     name string, so create-task requests were failing Joi validation)
    func postTask(title: String, description: String, budget: Double, currencyId: Int, priorityId: Int, serviceTypeId: Int, address: String, latitude: Double?, longitude: Double?, scheduledAt: Date?, preferredTimeOfDayId: Int?) async throws -> (task: TaskModel, message: String, type: String)
    
    func getRequesterPublishedTasks(cursor: String?, limit: Int?, status: String?) async throws -> PaginatedTasksResult
    func getRequesterCompletedTasks(cursor: String?, limit: Int?) async throws -> PaginatedTasksResult
    func getUnratedRequesterTasks(cursor: String?, limit: Int?) async throws -> PaginatedTasksResult
    
        // MARK: - Executor
    
    func getExecutorAvailableTasks(cursor: String?, limit: Int?, favoritesOnly: Bool) async throws -> PaginatedTasksResult
    func getExecutorAssignedTasks(cursor: String?, limit: Int?) async throws -> PaginatedTasksResult
    func getExecutorCompletedTasks(cursor: String?, limit: Int?) async throws -> PaginatedTasksResult
    func getUnratedExecutorTasks(cursor: String?, limit: Int?) async throws -> PaginatedTasksResult
    
        // MARK: - Requester Actions
    
    func deleteTask(id: String) async throws -> (message: String, type: String)
    func cancelTask(id: String) async throws -> (message: String, type: String)
    func publishTask(id: String) async throws -> (message: String, type: String)
    func confirmTask(id: String) async throws -> (message: String, type: String)
    func getApplicants(taskId: String) async throws -> [ApplicantModel]
    func assignExecutor(taskId: String, executorId: String) async throws -> (message: String, type: String)
    func declineApplicant(taskId: String, applicantId: String) async throws -> (message: String, type: String)
    
        // MARK: - Payments
    
    func retryPayment(taskId: String) async throws -> URL
    
        // MARK: - Executor Actions
    
    func applyToTask(id: String, proposedBudget: Double?) async throws -> (message: String, type: String)
    func withdrawFromTask(id: String) async throws -> WithdrawResult
    func markTaskDone(id: String) async throws -> (message: String, type: String)
    func favoriteTask(id: String) async throws -> (message: String, type: String)
    func unfavoriteTask(id: String) async throws -> (message: String, type: String)
    
        // MARK: - Rating Actions
    func rateExecutor(taskId: String, rating: Int, comment: String) async throws -> (message: String, type: String)
    func rateRequester(taskId: String, rating: Int, comment: String) async throws -> (message: String, type: String)
    
}
