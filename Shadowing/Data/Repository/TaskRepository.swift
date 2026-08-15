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
        DebugLogger.log("🔑 🟢 TaskRepository -> getValidToken - Started")
        defer { DebugLogger.log("🔑 🏁 TaskRepository -> getValidToken - Ended") }
        
        guard let token = try await authRepository.validAccessToken() else {
            throw AuthError.noSession
        }
        return token
    }
    
        // MARK: - Shared
    
    func getAllTasks(cursor: String?, limit: Int?) async throws -> PaginatedTasksResult {
        DebugLogger.log("🚀 🟢 TaskRepository -> getAllTasks - Started")
        defer { DebugLogger.log("🚀 🏁 TaskRepository -> getAllTasks - Ended") }
        
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
        DebugLogger.log("🔍 🟢 TaskRepository -> getTaskDetails - Started")
        defer { DebugLogger.log("🔍 🏁 TaskRepository -> getTaskDetails - Ended") }
        
        let token = try await getValidToken()
        let config = APIConfig.taskDetails(id: id, accessToken: token)
        let response: APIResponseDTO<SingleTaskResponseDTO> = try await network.request(config)
        return response.data.task.toDomain()
    }
    
        // MARK: - Map
    
    func getMapTasks(bounds: MapBounds) async throws -> MapTasksPage {
        DebugLogger.log("🗺️ 🟢 TaskRepository -> getMapTasks - Started")
        defer { DebugLogger.log("🗺️ 🏁 TaskRepository -> getMapTasks - Ended") }
        
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
        DebugLogger.log("📝 🟢 TaskRepository -> postTask - Started")
        defer { DebugLogger.log("📝 🏁 TaskRepository -> postTask - Ended") }
        
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
        DebugLogger.log("📤 🟢 TaskRepository -> getRequesterPublishedTasks - Started")
        defer { DebugLogger.log("📤 🏁 TaskRepository -> getRequesterPublishedTasks - Ended") }
        
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
        DebugLogger.log("🎉 🟢 TaskRepository -> getRequesterCompletedTasks - Started")
        defer { DebugLogger.log("🎉 🏁 TaskRepository -> getRequesterCompletedTasks - Ended") }
        
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
        DebugLogger.log("⭐ 🟢 TaskRepository -> getUnratedRequesterTasks - Started")
        defer { DebugLogger.log("⭐ 🏁 TaskRepository -> getUnratedRequesterTasks - Ended") }
        
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
        DebugLogger.log("📋 🟢 TaskRepository -> getExecutorAvailableTasks - Started")
        defer { DebugLogger.log("📋 🏁 TaskRepository -> getExecutorAvailableTasks - Ended") }
        
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
        DebugLogger.log("📌 🟢 TaskRepository -> getExecutorAssignedTasks - Started")
        defer { DebugLogger.log("📌 🏁 TaskRepository -> getExecutorAssignedTasks - Ended") }
        
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
        DebugLogger.log("✅ 🟢 TaskRepository -> getExecutorCompletedTasks - Started")
        defer { DebugLogger.log("✅ 🏁 TaskRepository -> getExecutorCompletedTasks - Ended") }
        
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
        DebugLogger.log("⭐ 🟢 TaskRepository -> getUnratedExecutorTasks - Started")
        defer { DebugLogger.log("⭐ 🏁 TaskRepository -> getUnratedExecutorTasks - Ended") }
        
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
        DebugLogger.log("🗑️ 🟢 TaskRepository -> deleteTask - Started")
        defer { DebugLogger.log("🗑️ 🏁 TaskRepository -> deleteTask - Ended") }
        
        let token = try await getValidToken()
        let config = APIConfig.requesterDeleteTask(id: id, accessToken: token)
        let response: APIResponseDTO<EmptyDataDTO> = try await network.request(config)
        
        return (message: response.message, type: response.type)
    }
    
    func cancelTask(id: String) async throws -> (message: String, type: String) {
        DebugLogger.log("🚫 🟢 TaskRepository -> cancelTask - Started")
        defer { DebugLogger.log("🚫 🏁 TaskRepository -> cancelTask - Ended") }
        
        let token = try await getValidToken()
        let config = APIConfig.requesterCancelTask(id: id, accessToken: token)
        let response: APIResponseDTO<EmptyDataDTO> = try await network.request(config)
        
        return (message: response.message, type: response.type)
    }
    
    func publishTask(id: String) async throws -> (message: String, type: String) {
        DebugLogger.log("📢 🟢 TaskRepository -> publishTask - Started")
        defer { DebugLogger.log("📢 🏁 TaskRepository -> publishTask - Ended") }
        
        let token = try await getValidToken()
        let config = APIConfig.requesterPublishTask(id: id, accessToken: token)
        let response: APIResponseDTO<EmptyDataDTO> = try await network.request(config)
        
        return (message: response.message, type: response.type)
    }
    
    func confirmTask(id: String) async throws -> (message: String, type: String) {
        DebugLogger.log("👍 🟢 TaskRepository -> confirmTask - Started")
        defer { DebugLogger.log("👍 🏁 TaskRepository -> confirmTask - Ended") }
        
        let token = try await getValidToken()
        let config = APIConfig.requesterConfirmTask(id: id, accessToken: token)
        let response: APIResponseDTO<EmptyDataDTO> = try await network.request(config)
        
        return (message: response.message, type: response.type)
    }
    
    func getApplicants(taskId: String) async throws -> [ApplicantModel] {
        DebugLogger.log("👥 🟢 TaskRepository -> getApplicants - Started")
        defer { DebugLogger.log("👥 🏁 TaskRepository -> getApplicants - Ended") }
        
        let token = try await getValidToken()
        let config = APIConfig.requesterApplicants(id: taskId, accessToken: token)
        let response: APIResponseDTO<ApplicantsDataDTO> = try await network.request(config)
        
        return response.data.applicants.map { $0.toDomain() }
    }
    
    func assignExecutor(taskId: String, executorId: String) async throws -> (message: String, type: String) {
        DebugLogger.log("🤝 🟢 TaskRepository -> assignExecutor - Started")
        defer { DebugLogger.log("🤝 🏁 TaskRepository -> assignExecutor - Ended") }
        
        let token = try await getValidToken()
        let body = APIConfig.RequesterAssignTaskBody(executorId: executorId)
        let config = APIConfig.requesterAssignTask(id: taskId, body: body, accessToken: token)
        let response: APIResponseDTO<EmptyDataDTO> = try await network.request(config)
        
        return (message: response.message, type: response.type)
    }
    
    func retryPayment(taskId: String) async throws -> URL {
        DebugLogger.log("💳 🟢 TaskRepository -> retryPayment - Started")
        defer { DebugLogger.log("💳 🏁 TaskRepository -> retryPayment - Ended") }
        
        let token = try await getValidToken()
        let config = APIConfig.initiatePayment(taskId: taskId, accessToken: token)
        let response: APIResponseDTO<PaymentResponseDTO> = try await network.request(config)
        
        guard let url = URL(string: response.data.paymentUrl) else {
            return URL(string: "https://example.com")!
        }
        
        return url
    }
    
    func declineApplicant(taskId: String, applicantId: String) async throws -> (message: String, type: String) {
        DebugLogger.log("❌ 🟢 TaskRepository -> declineApplicant - Started")
        defer { DebugLogger.log("❌ 🏁 TaskRepository -> declineApplicant - Ended") }
        
        let token = try await getValidToken()
        let config = APIConfig.requesterDeclineApplicant(taskId: taskId, applicantId: applicantId, accessToken: token)
        let response: APIResponseDTO<EmptyDataDTO> = try await network.request(config)
        
        return (message: response.message, type: response.type)
    }
    
        // MARK: - Executor Actions
    
    func applyToTask(id: String, proposedBudget: Double?) async throws -> (message: String, type: String) {
        DebugLogger.log("✋ 🟢 TaskRepository -> applyToTask - Started")
        defer { DebugLogger.log("✋ 🏁 TaskRepository -> applyToTask - Ended") }
        
        let token = try await getValidToken()
        let body = APIConfig.ExecutorApplyTaskBody(proposedBudget: proposedBudget)
        let config = APIConfig.executorApplyTask(id: id, body: body, accessToken: token)
        let response: APIResponseDTO<EmptyDataDTO> = try await network.request(config)
        
        return (message: response.message, type: response.type)
    }
    
    func withdrawFromTask(id: String) async throws -> WithdrawResult {
        DebugLogger.log("🏃 🟢 TaskRepository -> withdrawFromTask - Started")
        defer { DebugLogger.log("🏃 🏁 TaskRepository -> withdrawFromTask - Ended") }
        
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
        DebugLogger.log("✔️ 🟢 TaskRepository -> markTaskDone - Started")
        defer { DebugLogger.log("✔️ 🏁 TaskRepository -> markTaskDone - Ended") }
        
        let token = try await getValidToken()
        let config = APIConfig.executorMarkDone(id: id, accessToken: token)
        let response: APIResponseDTO<EmptyDataDTO> = try await network.request(config)
        
        return (message: response.message, type: response.type)
    }
    
    func favoriteTask(id: String) async throws -> (message: String, type: String) {
        DebugLogger.log("❤️ 🟢 TaskRepository -> favoriteTask - Started")
        defer { DebugLogger.log("❤️ 🏁 TaskRepository -> favoriteTask - Ended") }
        
        let token = try await getValidToken()
        let config = APIConfig.executorFavoriteTask(id: id, accessToken: token)
        let response: APIResponseDTO<EmptyDataDTO> = try await network.request(config)
        
        return (message: response.message, type: response.type)
    }
    
    func unfavoriteTask(id: String) async throws -> (message: String, type: String) {
        DebugLogger.log("💔 🟢 TaskRepository -> unfavoriteTask - Started")
        defer { DebugLogger.log("💔 🏁 TaskRepository -> unfavoriteTask - Ended") }
        
        let token = try await getValidToken()
        let config = APIConfig.executorUnfavoriteTask(id: id, accessToken: token)
        let response: APIResponseDTO<EmptyDataDTO> = try await network.request(config)
        
        return (message: response.message, type: response.type)
    }
    
        // MARK: - Rating Actions
    
    func rateExecutor(taskId: String, rating: Int, comment: String) async throws -> (message: String, type: String) {
        DebugLogger.log("🌟 🟢 TaskRepository -> rateExecutor - Started")
        defer { DebugLogger.log("🌟 🏁 TaskRepository -> rateExecutor - Ended") }
        
        let token = try await getValidToken()
        let body = APIConfig.RatingBody(rating: rating, comment: comment)
        let config = APIConfig.requesterRateExecutor(id: taskId, body: body, accessToken: token)
        let response: APIResponseDTO<EmptyDataDTO> = try await network.request(config)
        return (message: response.message, type: response.type)
    }
    
    func rateRequester(taskId: String, rating: Int, comment: String) async throws -> (message: String, type: String) {
        DebugLogger.log("🌟 🟢 TaskRepository -> rateRequester - Started")
        defer { DebugLogger.log("🌟 🏁 TaskRepository -> rateRequester - Ended") }
        
        let token = try await getValidToken()
        let body = APIConfig.RatingBody(rating: rating, comment: comment)
        let config = APIConfig.executorRateRequester(id: taskId, body: body, accessToken: token)
        let response: APIResponseDTO<EmptyDataDTO> = try await network.request(config)
        return (message: response.message, type: response.type)
    }
}
