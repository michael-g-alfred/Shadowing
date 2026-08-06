import Foundation
import MGNetworkingKit

final class TaskRepository: TaskRepositoryProtocol {
    
    private let network: MGNetworkServiceProtocol
    private let authRepository: AuthRepositoryProtocol
    
    init(
        network: MGNetworkServiceProtocol,
        authRepository: AuthRepositoryProtocol
    ) {
        self.network = network
        self.authRepository = authRepository
    }
    
    private func getValidToken() async throws -> String {
        guard let token = try await authRepository.validAccessToken() else {
            throw AuthError.noSession
        }
        return token
    }
    
        // MARK: - Shared
    
    func getAllTasks(cursor: String?, limit: Int?) async throws -> PaginatedTasksResult {
        let token = try await getValidToken()
        let config = APIConfig.allTasks(accessToken: token)
        let response: APIResponseDTO<TaskListResponseDTO> = try await network.request(config)
        
        return PaginatedTasksResult(
            tasks: response.data.tasks.map({ $0.toDomain() }),
            hasMore: response.data.hasMore,
            cursor: response.data.cursor
        )
    }
    
    func getTaskDetails(id: String) async throws -> TaskModel {
        let token = try await getValidToken()
        let config = APIConfig.taskDetails(id: id, accessToken: token)
        let response: APIResponseDTO<SingleTaskResponseDTO> = try await network.request(config)
        return response.data.task.toDomain()
    }
    
        // MARK: - Map
    
    func getMapTasks(bounds: MapBounds) async throws -> MapTasksPage {
        let token = try await getValidToken()
        let config = APIConfig.mapTasks(bounds: bounds, accessToken: token)
        let response: APIResponseDTO<MapTasksPage> = try await network.request(config)
        return MapTasksPage(tasks: response.data.tasks, truncated: response.data.truncated)
    }
    
        // MARK: - Requester
    
    func postTask(
        title: String,
        description: String,
        budget: Double,
        currencyId: Int,
        priorityId: Int,
        serviceTypeId: Int,
        address: String,
        latitude: Double?,
        longitude: Double?,
        scheduledAt: Date?,
        preferredTimeOfDayId: Int?
    ) async throws -> (task: TaskModel, message: String, type: String) {
        let token = try await getValidToken()
        
        let body = APIConfig.RequesterCreateTaskBody(
            title: title,
            description: description,
            budget: budget,
            serviceTypeId: serviceTypeId,
            address: address,
            currencyId: currencyId,
            priorityId: priorityId,
            latitude: latitude,
            longitude: longitude,
            scheduledAt: scheduledAt,
            preferredTimeOfDayId: preferredTimeOfDayId
        )
        
        let config = APIConfig.requesterCreateTask(
            body,
            accessToken: token
        )
        
        let response: APIResponseDTO<SingleTaskResponseDTO> = try await network.request(config)
        
        return (
            task: response.data.task.toDomain(),
            message: response.message,
            type: response.type
        )
    }
    
    func getRequesterPublishedTasks(cursor: String?, limit: Int?, status: String? = nil) async throws -> PaginatedTasksResult {
        let token = try await getValidToken()
        let config = APIConfig.requesterPublishedTasks(cursor: cursor, limit: limit, status: status, accessToken: token)
        let response: APIResponseDTO<TaskListResponseDTO> = try await network.request(config)
        
        return PaginatedTasksResult(
            tasks: response.data.tasks.map { $0.toDomain() },
            hasMore: response.data.hasMore,
            cursor: response.data.cursor
        )
    }
    
    func getRequesterCompletedTasks(cursor: String?, limit: Int?) async throws -> PaginatedTasksResult {
        let token = try await getValidToken()
        let config = APIConfig.requesterCompletedTasks(cursor: cursor, limit: limit, accessToken: token)
        let response: APIResponseDTO<TaskListResponseDTO> = try await network.request(config)
        
        return PaginatedTasksResult(
            tasks: response.data.tasks.map { $0.toDomain() },
            hasMore: response.data.hasMore,
            cursor: response.data.cursor
        )
    }
    
    func getUnratedRequesterTasks(cursor: String?, limit: Int?) async throws -> PaginatedTasksResult {
        let token = try await getValidToken()
        let config = APIConfig.requesterUnratedTasks(cursor: cursor, limit: limit, accessToken: token)
        let response: APIResponseDTO<TaskListResponseDTO> = try await network.request(config)
        
        return PaginatedTasksResult(
            tasks: response.data.tasks.map { $0.toDomain() },
            hasMore: response.data.hasMore,
            cursor: response.data.cursor
        )
    }
    
        // MARK: - Executor
    
    func getExecutorAvailableTasks(cursor: String?, limit: Int?, favoritesOnly: Bool = false) async throws -> PaginatedTasksResult {
        let token = try await getValidToken()
        let config = APIConfig.executorAvailableTasks(cursor: cursor, limit: limit, favoritesOnly: favoritesOnly, accessToken: token)
        let response: APIResponseDTO<TaskListResponseDTO> = try await network.request(config)
        
        return PaginatedTasksResult(
            tasks: response.data.tasks.map { $0.toDomain() },
            hasMore: response.data.hasMore,
            cursor: response.data.cursor
        )
    }
    
    func getExecutorAssignedTasks(cursor: String?, limit: Int?) async throws -> PaginatedTasksResult {
        let token = try await getValidToken()
        let config = APIConfig.executorAssignedTasks(cursor: cursor, limit: limit, accessToken: token)
        let response: APIResponseDTO<TaskListResponseDTO> = try await network.request(config)
        
        return PaginatedTasksResult(
            tasks: response.data.tasks.map { $0.toDomain() },
            hasMore: response.data.hasMore,
            cursor: response.data.cursor
        )
    }
    
    func getExecutorCompletedTasks(cursor: String?, limit: Int?) async throws -> PaginatedTasksResult {
        let token = try await getValidToken()
        let config = APIConfig.executorCompletedTasks(cursor: cursor, limit: limit, accessToken: token)
        let response: APIResponseDTO<TaskListResponseDTO> = try await network.request(config)
        
        return PaginatedTasksResult(
            tasks: response.data.tasks.map { $0.toDomain() },
            hasMore: response.data.hasMore,
            cursor: response.data.cursor
        )
    }
    
    func getUnratedExecutorTasks(cursor: String?, limit: Int?) async throws -> PaginatedTasksResult {
        let token = try await getValidToken()
        let config = APIConfig.executorUnratedTasks(cursor: cursor, limit: limit, accessToken: token)
        let response: APIResponseDTO<TaskListResponseDTO> = try await network.request(config)
        
        return PaginatedTasksResult(
            tasks: response.data.tasks.map { $0.toDomain() },
            hasMore: response.data.hasMore,
            cursor: response.data.cursor
        )
    }
    
        // MARK: - Requester Actions
    
    func deleteTask(id: String) async throws -> (message: String, type: String) {
        let token = try await getValidToken()
        let config = APIConfig.requesterDeleteTask(id: id, accessToken: token)
        let response: APIResponseDTO<EmptyDataDTO> = try await network.request(config)
        
        return (message: response.message, type: response.type)
    }
    
    func cancelTask(id: String) async throws -> (message: String, type: String) {
        let token = try await getValidToken()
        let config = APIConfig.requesterCancelTask(id: id, accessToken: token)
        let response: APIResponseDTO<EmptyDataDTO> = try await network.request(config)
        
        return (message: response.message, type: response.type)
    }
    
    func publishTask(id: String) async throws -> (message: String, type: String) {
        let token = try await getValidToken()
        let config = APIConfig.requesterPublishTask(id: id, accessToken: token)
        let response: APIResponseDTO<EmptyDataDTO> = try await network.request(config)
        
        return (message: response.message, type: response.type)
    }
    
    func confirmTask(id: String) async throws -> (message: String, type: String) {
        let token = try await getValidToken()
        let config = APIConfig.requesterConfirmTask(id: id, accessToken: token)
        let response: APIResponseDTO<EmptyDataDTO> = try await network.request(config)
        
        return (message: response.message, type: response.type)
    }
    
    func getApplicants(taskId: String) async throws -> [ApplicantModel] {
        let token = try await getValidToken()
        let config = APIConfig.requesterApplicants(id: taskId, accessToken: token)
        let response: APIResponseDTO<ApplicantsDataDTO> = try await network.request(config)
        
        return response.data.applicants.map { $0.toDomain() }
    }
    
    func assignExecutor(taskId: String, executorId: String) async throws -> (message: String, type: String) {
        let token = try await getValidToken()
        let body = APIConfig.RequesterAssignTaskBody(executorId: executorId)
        let config = APIConfig.requesterAssignTask(id: taskId, body: body, accessToken: token)
        let response: APIResponseDTO<EmptyDataDTO> = try await network.request(config)
        
        return (message: response.message, type: response.type)
    }
    
    func retryPayment(taskId: String) async throws -> URL {
        let token = try await getValidToken()
        let config = APIConfig.initiatePayment(taskId: taskId, accessToken: token)
        let response: APIResponseDTO<PaymentResponseDTO> = try await network.request(config)
        
        guard let url = URL(string: response.data.paymentUrl) else {
            return URL(string: "https://example.com")!
        }
        
        return url
    }
    
    func declineApplicant(taskId: String, applicantId: String) async throws -> (message: String, type: String) {
        let token = try await getValidToken()
        let config = APIConfig.requesterDeclineApplicant(taskId: taskId, applicantId: applicantId, accessToken: token)
        let response: APIResponseDTO<EmptyDataDTO> = try await network.request(config)
        
        return (message: response.message, type: response.type)
    }
    
        // MARK: - Executor Actions
    
    func applyToTask(id: String, proposedBudget: Double?) async throws -> (message: String, type: String) {
        let token = try await getValidToken()
        let body = APIConfig.ExecutorApplyTaskBody(proposedBudget: proposedBudget)
        let config = APIConfig.executorApplyTask(id: id, body: body, accessToken: token)
        let response: APIResponseDTO<EmptyDataDTO> = try await network.request(config)
        
        return (message: response.message, type: response.type)
    }
    
    func withdrawFromTask(id: String) async throws -> WithdrawResult {
        let token = try await getValidToken()
        let config = APIConfig.executorWithdrawTask(id: id, accessToken: token)
        let response: APIResponseDTO<WithdrawResponseDTO> = try await network.request(config)
        
        return WithdrawResult(
            message: response.message,
            type: response.type,
            suspended: response.data.suspended,
            warning: response.data.warning
        )
    }
    
    func markTaskDone(id: String) async throws -> (message: String, type: String) {
        let token = try await getValidToken()
        let config = APIConfig.executorMarkDone(id: id, accessToken: token)
        let response: APIResponseDTO<EmptyDataDTO> = try await network.request(config)
        
        return (message: response.message, type: response.type)
    }
    
    func favoriteTask(id: String) async throws -> (message: String, type: String) {
        let token = try await getValidToken()
        let config = APIConfig.executorFavoriteTask(id: id, accessToken: token)
        let response: APIResponseDTO<EmptyDataDTO> = try await network.request(config)
        
        return (message: response.message, type: response.type)
    }
    
    func unfavoriteTask(id: String) async throws -> (message: String, type: String) {
        let token = try await getValidToken()
        let config = APIConfig.executorUnfavoriteTask(id: id, accessToken: token)
        let response: APIResponseDTO<EmptyDataDTO> = try await network.request(config)
        
        return (message: response.message, type: response.type)
    }
    
        // MARK: - Rating Actions
    
    func rateExecutor(taskId: String, rating: Int, comment: String) async throws -> (message: String, type: String) {
        let token = try await getValidToken()
        let body = APIConfig.RatingBody(rating: rating, comment: comment)
        let config = APIConfig.requesterRateExecutor(id: taskId, body: body, accessToken: token)
        let response: APIResponseDTO<EmptyDataDTO> = try await network.request(config)
        return (message: response.message, type: response.type)
    }
    
    func rateRequester(taskId: String, rating: Int, comment: String) async throws -> (message: String, type: String) {
        let token = try await getValidToken()
        let body = APIConfig.RatingBody(rating: rating, comment: comment)
        let config = APIConfig.executorRateRequester(id: taskId, body: body, accessToken: token)
        let response: APIResponseDTO<EmptyDataDTO> = try await network.request(config)
        return (message: response.message, type: response.type)
    }
}
