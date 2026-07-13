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
        
        DebugLogger.log("🚀 TaskRepository initialized")
    }
    
    private func getValidToken() async throws -> String {
        DebugLogger.log("🔑 Getting valid access token...")
        
        guard let token = try await authRepository.validAccessToken() else {
            DebugLogger.log("❌ No valid session found")
            throw AuthError.noSession
        }
        
        DebugLogger.log("✅ Access token acquired")
        return token
    }
    
        // MARK: - Shared
    
    func getAllTasks(cursor: String?, limit: Int?) async throws -> PaginatedTasksResult {
        let token = try await getValidToken()
        let config = APIConfig.allTasks(accessToken: token)
        let response: APIResponseDTO<TaskListResponseDTO> = try await network.request(config)
        
        return PaginatedTasksResult(
            tasks: response.data.tasks.map({$0.toDomain()}),
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
    
    func postTask( title: String, description: String, budget: Double, priority: TaskPriority, serviceType: String, address: String, latitude: Double?, longitude: Double?, scheduledAt: Date?, preferredTimeOfDay: PreferredTimeOfDay? ) async throws -> TaskModel {
        
        DebugLogger.log("══════════════════════════════════════")
        DebugLogger.log("📝 Posting New Task")
        
        do {
            let token = try await getValidToken()
            
            let body = APIConfig.RequesterCreateTaskBody(
                title: title,
                description: description,
                budget: budget,
                serviceType: serviceType,
                address: address,
                currency: "EGP",
                priority: priority.rawValue,
                latitude: latitude,
                longitude: longitude,
                scheduledAt: scheduledAt,
                preferredTimeOfDay: preferredTimeOfDay?.rawValue
            )
            
            DebugLogger.log("🌐 Sending POST request...")
            
            let config = APIConfig.requesterCreateTask(
                body,
                accessToken: token
            )
            
            let response: APIResponseDTO<SingleTaskResponseDTO> = try await network.request(config)
            
            DebugLogger.log("✅ Task created successfully")
            DebugLogger.log("🆔 Task ID: \(response.data.task.id)")
            DebugLogger.log("══════════════════════════════════════")
            
            return response.data.task.toDomain()
            
        } catch {
            DebugLogger.log("❌ Failed to create task")
            DebugLogger.log("❌ Error: \(error)")
            DebugLogger.log("══════════════════════════════════════")
            throw error
        }
    }
    
    func getRequesterPublishedTasks(cursor: String?, limit: Int?) async throws -> PaginatedTasksResult {
        DebugLogger.log("══════════════════════════════════════")
        DebugLogger.log("📤 Fetching Requester Published Tasks (cursor: \(cursor ?? "nil"))")
        
        let token = try await getValidToken()
        
        DebugLogger.log("🌐 Sending request...")
        
        let config = APIConfig.requesterPublishedTasks( cursor: cursor, limit: limit, accessToken: token )
        let response: APIResponseDTO<TaskListResponseDTO> = try await network.request(config)
        
        DebugLogger.log("✅ Request succeeded")
        DebugLogger.log("📋 Tasks Count: \(response.data.tasks.count), hasMore: \(response.data.hasMore)")
        DebugLogger.log("══════════════════════════════════════")
        
        return PaginatedTasksResult(
            tasks: response.data.tasks.map { $0.toDomain() },
            hasMore: response.data.hasMore,
            cursor: response.data.cursor
        )
    }
    
    func getRequesterCompletedTasks(cursor: String?, limit: Int?) async throws -> PaginatedTasksResult {
        DebugLogger.log("══════════════════════════════════════")
        DebugLogger.log("✅ Fetching Requester Completed Tasks (cursor: \(cursor ?? "nil"))")
        
        let token = try await getValidToken()
        
        DebugLogger.log("🌐 Sending request...")
        
        let config = APIConfig.requesterCompletedTasks(cursor: cursor, limit: limit, accessToken: token)
        let response: APIResponseDTO<TaskListResponseDTO> = try await network.request(config)
        
        DebugLogger.log("✅ Request succeeded")
        DebugLogger.log("📋 Tasks Count: \(response.data.tasks.count), hasMore: \(response.data.hasMore)")
        DebugLogger.log("══════════════════════════════════════")
        
        return PaginatedTasksResult(
            tasks: response.data.tasks.map { $0.toDomain() },
            hasMore: response.data.hasMore,
            cursor: response.data.cursor
        )
    }
    
        // MARK: - Executor
    
    func getExecutorAvailableTasks(cursor: String?, limit: Int?) async throws -> PaginatedTasksResult {
        DebugLogger.log("══════════════════════════════════════")
        DebugLogger.log("📥 Fetching Executor Available Tasks (cursor: \(cursor ?? "nil"))")
        
        let token = try await getValidToken()
        
        DebugLogger.log("🌐 Sending request...")
        
        let config = APIConfig.executorAvailableTasks (cursor: cursor, limit: limit, accessToken: token)
        let response: APIResponseDTO<TaskListResponseDTO> = try await network.request(config)
        
        DebugLogger.log("✅ Request succeeded")
        DebugLogger.log("📋 Tasks Count: \(response.data.tasks.count), hasMore: \(response.data.hasMore)")
        DebugLogger.log("══════════════════════════════════════")
        
        return PaginatedTasksResult(
            tasks: response.data.tasks.map { $0.toDomain() },
            hasMore: response.data.hasMore,
            cursor: response.data.cursor
        )
    }
    
    func getExecutorAssignedTasks(cursor: String?, limit: Int?) async throws -> PaginatedTasksResult {
        DebugLogger.log("══════════════════════════════════════")
        DebugLogger.log("🛠️ Fetching Executor Assigned Tasks (cursor: \(cursor ?? "nil"))")
        
        let token = try await getValidToken()
        
        DebugLogger.log("🌐 Sending request...")
        
        let config = APIConfig.executorAssignedTasks(cursor: cursor, limit: limit, accessToken: token)
        let response: APIResponseDTO<TaskListResponseDTO> = try await network.request(config)
        
        DebugLogger.log("✅ Request succeeded")
        DebugLogger.log("📋 Tasks Count: \(response.data.tasks.count), hasMore: \(response.data.hasMore)")
        DebugLogger.log("══════════════════════════════════════")
        
        return PaginatedTasksResult(
            tasks: response.data.tasks.map { $0.toDomain() },
            hasMore: response.data.hasMore,
            cursor: response.data.cursor
        )
    }
    
    func getExecutorCompletedTasks(cursor: String?, limit: Int?) async throws -> PaginatedTasksResult {
        DebugLogger.log("══════════════════════════════════════")
        DebugLogger.log("🏁 Fetching Executor Completed Tasks (cursor: \(cursor ?? "nil"))")
        
        let token = try await getValidToken()
        
        DebugLogger.log("🌐 Sending request...")
        
        let config = APIConfig.executorCompletedTasks(cursor: cursor, limit: limit, accessToken: token)
        let response: APIResponseDTO<TaskListResponseDTO> = try await network.request(config)
        
        DebugLogger.log("✅ Request succeeded")
        DebugLogger.log("📋 Tasks Count: \(response.data.tasks.count), hasMore: \(response.data.hasMore)")
        DebugLogger.log("══════════════════════════════════════")
        
        return PaginatedTasksResult(
            tasks: response.data.tasks.map { $0.toDomain() },
            hasMore: response.data.hasMore,
            cursor: response.data.cursor
        )
    }
    
        // MARK: - Requester Actions
    
    func deleteTask(id: String) async throws {
        DebugLogger.log("══════════════════════════════════════")
        DebugLogger.log("🗑️ Deleting Task \(id)")
        
        let token = try await getValidToken()
        let config = APIConfig.requesterDeleteTask(id: id, accessToken: token)
        let _: () = try await network.requestWithoutResponse(config)
        
        
        DebugLogger.log("✅ Task Deleted")
        DebugLogger.log("══════════════════════════════════════")
    }
    
    func cancelTask(id: String) async throws {
        DebugLogger.log("══════════════════════════════════════")
        DebugLogger.log("🚫 Cancelling Task \(id)")
        
        let token = try await getValidToken()
        let config = APIConfig.requesterCancelTask(id: id, accessToken: token)
        let _: () = try await network.requestWithoutResponse(config)
        
        DebugLogger.log("✅ Task Cancelled")
        DebugLogger.log("══════════════════════════════════════")
    }
    
    func publishTask(id: String) async throws {
        DebugLogger.log("══════════════════════════════════════")
        DebugLogger.log("🚫 Cancelling Task \(id)")
        
        let token = try await getValidToken()
        let config = APIConfig.requesterPublishTask(id: id, accessToken: token)
        let _: () = try await network.requestWithoutResponse(config)
        
        DebugLogger.log("✅ Task Cancelled")
        DebugLogger.log("══════════════════════════════════════")
    }
    
    func confirmTask(id: String) async throws {
        DebugLogger.log("══════════════════════════════════════")
        DebugLogger.log("✅ Confirming Task Completion \(id)")
        
        let token = try await getValidToken()
        let config = APIConfig.requesterConfirmTask(id: id, accessToken: token)
        let _: () = try await network.requestWithoutResponse(config)
        
        DebugLogger.log("✅ Task Confirmed")
        DebugLogger.log("══════════════════════════════════════")
    }
    
    func getApplicants(taskId: String) async throws -> [ApplicantModel] {
        DebugLogger.log("══════════════════════════════════════")
        DebugLogger.log("👥 Fetching Applicants for Task \(taskId)")
        
        let token = try await getValidToken()
        let config = APIConfig.requesterApplicants(id: taskId, accessToken: token)
        let response: APIResponseDTO<ApplicantsDataDTO> = try await network.request(config)
        
        DebugLogger.log("✅ Applicants Count: \(response.data.applicants.count)")
        DebugLogger.log("══════════════════════════════════════")
        
        return response.data.applicants.map { $0.toDomain() }
    }
    
//    func assignExecutor(taskId: String, executorId: String) async throws -> URL {
//        DebugLogger.log("══════════════════════════════════════")
//        DebugLogger.log("🧑‍🔧 Assigning Executor \(executorId) to Task \(taskId)")
//        
//        let token = try await getValidToken()
//        let body = APIConfig.RequesterAssignTaskBody(executorId: executorId)
//        let config = APIConfig.requesterAssignTask(id: taskId, body: body, accessToken: token)
//        let response: APIResponseDTO<PaymentResponseDTO> = try await network.request(config)
//        
//        guard let url = URL(string: response.data.paymentUrl) else {
//            DebugLogger.log("❌ Invalid payment URL received")
//            return URL(string: "https://example.com")!
//        }
//        
//        DebugLogger.log("✅ Executor Assigned, payment initiated")
//        DebugLogger.log("══════════════════════════════════════")
//        
//        return url
//    }
    
    func assignExecutor(taskId: String, executorId: String) async throws {
        DebugLogger.log("══════════════════════════════════════")
        DebugLogger.log("🧑‍🔧 Assigning Executor \(executorId) to Task \(taskId)")
        
        let token = try await getValidToken()
        let body = APIConfig.RequesterAssignTaskBody(executorId: executorId)
        let config = APIConfig.requesterAssignTask(id: taskId, body: body, accessToken: token)
        let _: () = try await network.requestWithoutResponse(config)
        DebugLogger.log("✅ Executor Assigned")
    }
    
        // Retry payment for a task that's already assigned but whose escrow
        // is still "not_paid" (e.g. a previous payment attempt failed).
    func retryPayment(taskId: String) async throws -> URL {
        DebugLogger.log("══════════════════════════════════════")
        DebugLogger.log("💳 Retrying Payment for Task \(taskId)")
        
        let token = try await getValidToken()
        let config = APIConfig.initiatePayment(taskId: taskId, accessToken: token)
        let response: APIResponseDTO<PaymentResponseDTO> = try await network.request(config)
        
        guard let url = URL(string: response.data.paymentUrl) else {
            return URL(string: "https://example.com")!
        }
        
        DebugLogger.log("✅ Payment retry initiated")
        DebugLogger.log("══════════════════════════════════════")
        
        return url
    }
    
    func declineApplicant(taskId: String, applicantId: String) async throws {
        DebugLogger.log("══════════════════════════════════════")
        DebugLogger.log("🚫 Declining Applicant \(applicantId) for Task \(taskId)")
        
        let token = try await getValidToken()
        let config = APIConfig.requesterDeclineApplicant(taskId: taskId, applicantId: applicantId, accessToken: token)
        let _: () = try await network.requestWithoutResponse(config)
        
        DebugLogger.log("✅ Applicant Declined")
        DebugLogger.log("══════════════════════════════════════")
    }
    
        // MARK: - Executor Actions
    
    func applyToTask(id: String, proposedBudget: Double?) async throws {
        DebugLogger.log("══════════════════════════════════════")
        DebugLogger.log("🙋 Applying to Task \(id)")
        
        let token = try await getValidToken()
        let body = APIConfig.ExecutorApplyTaskBody(proposedBudget: proposedBudget)
        let config = APIConfig.executorApplyTask(id: id, body: body, accessToken: token)
        let _: () = try await network.requestWithoutResponse(config)
        
        DebugLogger.log("✅ Applied Successfully")
        DebugLogger.log("══════════════════════════════════════")
    }
    
    func withdrawFromTask(id: String) async throws {
        DebugLogger.log("══════════════════════════════════════")
        DebugLogger.log("↩️ Withdrawing from Task \(id)")
        
        let token = try await getValidToken()
        let config = APIConfig.executorWithdrawTask(id: id, accessToken: token)
        let _: () = try await network.requestWithoutResponse(config)
        
        DebugLogger.log("✅ Withdrawn Successfully")
        DebugLogger.log("══════════════════════════════════════")
    }
    
    func markTaskDone(id: String) async throws {
        DebugLogger.log("══════════════════════════════════════")
        DebugLogger.log("🏁 Marking Task Done \(id)")
        
        let token = try await getValidToken()
        let config = APIConfig.executorMarkDone(id: id, accessToken: token)
        let _: () = try await network.requestWithoutResponse(config)
        
        DebugLogger.log("✅ Task Marked Done")
        DebugLogger.log("══════════════════════════════════════")
    }
    
        // MARK: - Rating Actions
    func rateExecutor(taskId: String, rating: Int, comment: String) async throws {
        let token = try await getValidToken()
        let body = APIConfig.RatingBody(rating: rating, comment: comment)
        let config = APIConfig.requesterRateExecutor(id: taskId, body: body, accessToken: token)
        _ = try await network.requestWithoutResponse(config)
    }
    
    func rateRequester(taskId: String, rating: Int, comment: String) async throws {
        let token = try await getValidToken()
        let body = APIConfig.RatingBody(rating: rating, comment: comment)
        let config = APIConfig.executorRateRequester(id: taskId, body: body, accessToken: token)
        _ = try await network.requestWithoutResponse(config)
    }
}
