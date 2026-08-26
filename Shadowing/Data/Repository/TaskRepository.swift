import Foundation
import MGNetworkingKit

/// Handles all task-related REST operations: browsing, map queries,
/// requester actions (posting, assigning, canceling), executor actions
/// (applying, withdrawing, completing), and post-completion ratings.
///
/// Every method logs a start/end pair via `DebugLogger` with a
/// method-specific emoji tag.
final class TaskRepository: TaskRepositoryProtocol {

    /// Networking layer used to perform REST requests.
    private let network: MGNetworkServiceProtocol

    /// Auth repository used to obtain a valid access token for each request.
    private let authRepository: AuthRepositoryProtocol

    /// Creates a task repository.
    ///
    /// - Parameters:
    ///   - network: Networking service used to perform REST requests.
    ///   - authRepository: Auth repository used to obtain access tokens.
    init(
        network: MGNetworkServiceProtocol,
        authRepository: AuthRepositoryProtocol
    ) {
        self.network = network
        self.authRepository = authRepository
    }

    /// Obtains a valid access token, throwing if there is no active session.
    ///
    /// - Returns: A valid access token.
    /// - Throws: ``AuthError/noSession`` if there is no signed-in user.
    private func getValidToken() async throws -> String {
        DebugLogger.log("🔑 🟢 TaskRepository -> getValidToken - Started")
        defer { DebugLogger.log("🔑 🏁 TaskRepository -> getValidToken - Ended") }

        guard let token = try await authRepository.validAccessToken() else {
            throw AuthError.noSession
        }
        return token
    }

    // MARK: - Pagination Helper

    /// Builds a ``PaginatedTasksResult`` from a raw task list response,
    /// guarding against a malformed (empty but non-nil) cursor so pagination
    /// doesn't spin on a broken "next page" pointer.
    ///
    /// - Parameter data: The raw, decoded task list response.
    /// - Returns: A ``PaginatedTasksResult`` with `hasMore`/`cursor` coerced
    ///   to a safe "end of pagination" state if the cursor looks invalid.
    private static func makePaginatedResult(from data: TaskListResponseDTO) -> PaginatedTasksResult {
        if let cursor = data.cursor, cursor.isEmpty {
            DebugLogger.log("⚠️ TaskRepository -> empty cursor returned; treating as end of pagination")
            return PaginatedTasksResult(
                tasks: data.tasks.map { $0.toDomain() },
                hasMore: false,
                cursor: nil
            )
        }

        return PaginatedTasksResult(
            tasks: data.tasks.map { $0.toDomain() },
            hasMore: data.hasMore,
            cursor: data.cursor
        )
    }

    // MARK: - Shared

    /// Fetches a paginated list of all tasks.
    ///
    /// - Parameters:
    ///   - cursor: An opaque pagination cursor from a previous call, or
    ///     `nil` to fetch the first page.
    ///   - limit: Maximum number of tasks to return.
    ///   - search: An optional case-insensitive title/description search term.
    /// - Returns: A ``PaginatedTasksResult`` with the tasks, a `hasMore`
    ///   flag, and the next cursor.
    /// - Throws: A networking error, or ``AuthError/noSession``.
    func getAllTasks(cursor: String?, limit: Int?, search: String? = nil) async throws -> PaginatedTasksResult {
        DebugLogger.log("🚀 🟢 TaskRepository -> getAllTasks - Started")
        defer { DebugLogger.log("🚀 🏁 TaskRepository -> getAllTasks - Ended") }

        let token = try await getValidToken()
        let config = APIConfig.allTasks(cursor: cursor, limit: limit, search: search, accessToken: token)
        let response: APIResponseDTO<TaskListResponseDTO> = try await network.request(config)

        return Self.makePaginatedResult(from: response.data)
    }

    /// Fetches the full details of a single task.
    ///
    /// - Parameter id: The task's ID.
    /// - Returns: The ``TaskModel`` for the given ID.
    /// - Throws: A networking error, or ``AuthError/noSession``.
    func getTaskDetails(id: String) async throws -> TaskModel {
        DebugLogger.log("🔍 🟢 TaskRepository -> getTaskDetails - Started")
        defer { DebugLogger.log("🔍 🏁 TaskRepository -> getTaskDetails - Ended") }

        let token = try await getValidToken()
        let config = APIConfig.taskDetails(id: id, accessToken: token)
        let response: APIResponseDTO<SingleTaskResponseDTO> = try await network.request(config)
        return response.data.task.toDomain()
    }

    // MARK: - Map

    /// Fetches tasks within a geographic bounding box, for map display.
    ///
    /// - Parameter bounds: The map viewport's geographic bounds.
    /// - Returns: A ``MapTasksPage`` containing the tasks in view and
    ///   whether the result set was truncated.
    /// - Throws: A networking error, or ``AuthError/noSession``.
    func getMapTasks(bounds: MapBounds) async throws -> MapTasksPage {
        DebugLogger.log("🗺️ 🟢 TaskRepository -> getMapTasks - Started")
        defer { DebugLogger.log("🗺️ 🏁 TaskRepository -> getMapTasks - Ended") }

        let token = try await getValidToken()
        let config = APIConfig.mapTasks(bounds: bounds, accessToken: token)
        let response: APIResponseDTO<MapTasksPageDTO> = try await network.request(config)

        // Map to domain and drop tasks without a coordinate here, in the
        // repository, so the presentation layer never touches DTOs.
        let tasks = response.data.tasks
            .map { $0.toDomain() }
            .filter { $0.coordinate != nil }
        return MapTasksPage(tasks: tasks, truncated: response.data.truncated)
    }

    // MARK: - Requester

    /// Creates a new task as the requester.
    ///
    /// - Parameters:
    ///   - title: The task's title.
    ///   - description: The task's description.
    ///   - budget: The proposed budget.
    ///   - currencyId: Lookup ID of the budget's currency.
    ///   - priorityId: Lookup ID of the task's priority.
    ///   - serviceTypeId: Lookup ID of the required service type.
    ///   - address: A human-readable address for the task location.
    ///   - latitude: Optional latitude of the task location.
    ///   - longitude: Optional longitude of the task location.
    ///   - scheduledAt: Optional scheduled date/time for the task.
    ///   - preferredTimeOfDayId: Optional lookup ID for a preferred time of day.
    /// - Returns: A tuple of the created ``TaskModel``, a server message,
    ///   and a message type.
    /// - Throws: A networking error, or ``AuthError/noSession``.
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

    /// Fetches the requester's published (open) tasks.
    ///
    /// - Parameters:
    ///   - cursor: An opaque pagination cursor, or `nil` for the first page.
    ///   - limit: Maximum number of tasks to return.
    ///   - status: Optional status filter.
    /// - Returns: A ``PaginatedTasksResult``.
    /// - Throws: A networking error, or ``AuthError/noSession``.
    func getRequesterPublishedTasks(cursor: String?, limit: Int?, status: String? = nil) async throws -> PaginatedTasksResult {
        DebugLogger.log("📤 🟢 TaskRepository -> getRequesterPublishedTasks - Started")
        defer { DebugLogger.log("📤 🏁 TaskRepository -> getRequesterPublishedTasks - Ended") }

        let token = try await getValidToken()
        let config = APIConfig.requesterPublishedTasks(cursor: cursor, limit: limit, status: status, accessToken: token)
        let response: APIResponseDTO<TaskListResponseDTO> = try await network.request(config)

        return Self.makePaginatedResult(from: response.data)
    }

    /// Fetches the requester's completed tasks.
    ///
    /// - Parameters:
    ///   - cursor: An opaque pagination cursor, or `nil` for the first page.
    ///   - limit: Maximum number of tasks to return.
    /// - Returns: A ``PaginatedTasksResult``.
    /// - Throws: A networking error, or ``AuthError/noSession``.
    func getRequesterCompletedTasks(cursor: String?, limit: Int?) async throws -> PaginatedTasksResult {
        DebugLogger.log("🎉 🟢 TaskRepository -> getRequesterCompletedTasks - Started")
        defer { DebugLogger.log("🎉 🏁 TaskRepository -> getRequesterCompletedTasks - Ended") }

        let token = try await getValidToken()
        let config = APIConfig.requesterCompletedTasks(cursor: cursor, limit: limit, accessToken: token)
        let response: APIResponseDTO<TaskListResponseDTO> = try await network.request(config)

        return Self.makePaginatedResult(from: response.data)
    }

    /// Fetches the requester's completed tasks that are still pending a
    /// rating from the requester (i.e. the requester has not rated the
    /// executor yet).
    ///
    /// - Parameters:
    ///   - cursor: An opaque pagination cursor, or `nil` for the first page.
    ///   - limit: Maximum number of tasks to return.
    /// - Returns: A ``PaginatedTasksResult``.
    /// - Throws: A networking error, or ``AuthError/noSession``.
    func getPendingRatingsForRequester(cursor: String?, limit: Int?) async throws -> PaginatedTasksResult {
        DebugLogger.log("⭐ 🟢 TaskRepository -> getPendingRatingsForRequester - Started")
        defer { DebugLogger.log("⭐ 🏁 TaskRepository -> getPendingRatingsForRequester - Ended") }

        let token = try await getValidToken()
        let config = APIConfig.requesterUnratedTasks(cursor: cursor, limit: limit, accessToken: token)
        let response: APIResponseDTO<TaskListResponseDTO> = try await network.request(config)

        return Self.makePaginatedResult(from: response.data)
    }

    // MARK: - Executor

    /// Fetches tasks available for an executor to apply to.
    ///
    /// - Parameters:
    ///   - cursor: An opaque pagination cursor, or `nil` for the first page.
    ///   - limit: Maximum number of tasks to return.
    ///   - favoritesOnly: If `true`, restricts results to favorited tasks.
    ///   - search: An optional case-insensitive title/description search term.
    /// - Returns: A ``PaginatedTasksResult``.
    /// - Throws: A networking error, or ``AuthError/noSession``.
    func getExecutorAvailableTasks(cursor: String?, limit: Int?, favoritesOnly: Bool = false, search: String? = nil) async throws -> PaginatedTasksResult {
        DebugLogger.log("📋 🟢 TaskRepository -> getExecutorAvailableTasks - Started")
        defer { DebugLogger.log("📋 🏁 TaskRepository -> getExecutorAvailableTasks - Ended") }

        let token = try await getValidToken()
        let config = APIConfig.executorAvailableTasks(cursor: cursor, limit: limit, favoritesOnly: favoritesOnly, search: search, accessToken: token)
        let response: APIResponseDTO<TaskListResponseDTO> = try await network.request(config)

        return Self.makePaginatedResult(from: response.data)
    }

    /// Fetches tasks currently assigned to the executor.
    ///
    /// - Parameters:
    ///   - cursor: An opaque pagination cursor, or `nil` for the first page.
    ///   - limit: Maximum number of tasks to return.
    /// - Returns: A ``PaginatedTasksResult``.
    /// - Throws: A networking error, or ``AuthError/noSession``.
    func getExecutorAssignedTasks(cursor: String?, limit: Int?) async throws -> PaginatedTasksResult {
        DebugLogger.log("📌 🟢 TaskRepository -> getExecutorAssignedTasks - Started")
        defer { DebugLogger.log("📌 🏁 TaskRepository -> getExecutorAssignedTasks - Ended") }

        let token = try await getValidToken()
        let config = APIConfig.executorAssignedTasks(cursor: cursor, limit: limit, accessToken: token)
        let response: APIResponseDTO<TaskListResponseDTO> = try await network.request(config)

        return Self.makePaginatedResult(from: response.data)
    }

    /// Fetches tasks the executor has completed.
    ///
    /// - Parameters:
    ///   - cursor: An opaque pagination cursor, or `nil` for the first page.
    ///   - limit: Maximum number of tasks to return.
    /// - Returns: A ``PaginatedTasksResult``.
    /// - Throws: A networking error, or ``AuthError/noSession``.
    func getExecutorCompletedTasks(cursor: String?, limit: Int?) async throws -> PaginatedTasksResult {
        DebugLogger.log("✅ 🟢 TaskRepository -> getExecutorCompletedTasks - Started")
        defer { DebugLogger.log("✅ 🏁 TaskRepository -> getExecutorCompletedTasks - Ended") }

        let token = try await getValidToken()
        let config = APIConfig.executorCompletedTasks(cursor: cursor, limit: limit, accessToken: token)
        let response: APIResponseDTO<TaskListResponseDTO> = try await network.request(config)

        return Self.makePaginatedResult(from: response.data)
    }

    /// Fetches the executor's completed tasks that are still pending a
    /// rating from the executor (i.e. the executor has not rated the
    /// requester yet).
    ///
    /// - Parameters:
    ///   - cursor: An opaque pagination cursor, or `nil` for the first page.
    ///   - limit: Maximum number of tasks to return.
    /// - Returns: A ``PaginatedTasksResult``.
    /// - Throws: A networking error, or ``AuthError/noSession``.
    func getPendingRatingsForExecutor(cursor: String?, limit: Int?) async throws -> PaginatedTasksResult {
        DebugLogger.log("⭐ 🟢 TaskRepository -> getPendingRatingsForExecutor - Started")
        defer { DebugLogger.log("⭐ 🏁 TaskRepository -> getPendingRatingsForExecutor - Ended") }

        let token = try await getValidToken()
        let config = APIConfig.executorUnratedTasks(cursor: cursor, limit: limit, accessToken: token)
        let response: APIResponseDTO<TaskListResponseDTO> = try await network.request(config)

        return Self.makePaginatedResult(from: response.data)
    }

    // MARK: - Requester Actions

    /// Deletes a task (requester-only).
    ///
    /// - Parameter id: The task's ID.
    /// - Returns: A tuple of a server message and message type.
    /// - Throws: A networking error, or ``AuthError/noSession``.
    func deleteTask(id: String) async throws -> (message: String, type: String) {
        DebugLogger.log("🗑️ 🟢 TaskRepository -> deleteTask - Started")
        defer { DebugLogger.log("🗑️ 🏁 TaskRepository -> deleteTask - Ended") }

        let token = try await getValidToken()
        let config = APIConfig.requesterDeleteTask(id: id, accessToken: token)
        let response: APIResponseDTO<EmptyDataDTO> = try await network.request(config)

        return (message: response.message, type: response.type)
    }

    /// Cancels a task (requester-only).
    ///
    /// - Parameter id: The task's ID.
    /// - Returns: A tuple of a server message and message type.
    /// - Throws: A networking error, or ``AuthError/noSession``.
    func cancelTask(id: String) async throws -> (message: String, type: String) {
        DebugLogger.log("🚫 🟢 TaskRepository -> cancelTask - Started")
        defer { DebugLogger.log("🚫 🏁 TaskRepository -> cancelTask - Ended") }

        let token = try await getValidToken()
        let config = APIConfig.requesterCancelTask(id: id, accessToken: token)
        let response: APIResponseDTO<EmptyDataDTO> = try await network.request(config)

        return (message: response.message, type: response.type)
    }

    /// Publishes a draft task, making it visible to executors.
    ///
    /// - Parameter id: The task's ID.
    /// - Returns: A tuple of a server message and message type.
    /// - Throws: A networking error, or ``AuthError/noSession``.
    func publishTask(id: String) async throws -> (message: String, type: String) {
        DebugLogger.log("📢 🟢 TaskRepository -> publishTask - Started")
        defer { DebugLogger.log("📢 🏁 TaskRepository -> publishTask - Ended") }

        let token = try await getValidToken()
        let config = APIConfig.requesterPublishTask(id: id, accessToken: token)
        let response: APIResponseDTO<EmptyDataDTO> = try await network.request(config)

        return (message: response.message, type: response.type)
    }

    /// Confirms a completed task (requester-only), finalizing it.
    ///
    /// - Parameter id: The task's ID.
    /// - Returns: A tuple of a server message and message type.
    /// - Throws: A networking error, or ``AuthError/noSession``.
    func confirmTask(id: String) async throws -> (message: String, type: String) {
        DebugLogger.log("👍 🟢 TaskRepository -> confirmTask - Started")
        defer { DebugLogger.log("👍 🏁 TaskRepository -> confirmTask - Ended") }

        let token = try await getValidToken()
        let config = APIConfig.requesterConfirmTask(id: id, accessToken: token)
        let response: APIResponseDTO<EmptyDataDTO> = try await network.request(config)

        return (message: response.message, type: response.type)
    }

    /// Fetches the applicants for a task (requester-only).
    ///
    /// - Parameter taskId: The task's ID.
    /// - Returns: An array of ``ApplicantModel``s.
    /// - Throws: A networking error, or ``AuthError/noSession``.
    func getApplicants(taskId: String) async throws -> [ApplicantModel] {
        DebugLogger.log("👥 🟢 TaskRepository -> getApplicants - Started")
        defer { DebugLogger.log("👥 🏁 TaskRepository -> getApplicants - Ended") }

        let token = try await getValidToken()
        let config = APIConfig.requesterApplicants(id: taskId, accessToken: token)
        let response: APIResponseDTO<ApplicantsDataDTO> = try await network.request(config)

        return response.data.applicants.map { $0.toDomain() }
    }

    /// Assigns an executor to a task (requester-only).
    ///
    /// - Parameters:
    ///   - taskId: The task's ID.
    ///   - executorId: The executor's user ID to assign.
    /// - Returns: A tuple of a server message and message type.
    /// - Throws: A networking error, or ``AuthError/noSession``.
    func assignExecutor(taskId: String, executorId: String) async throws -> (message: String, type: String) {
        DebugLogger.log("🤝 🟢 TaskRepository -> assignExecutor - Started")
        defer { DebugLogger.log("🤝 🏁 TaskRepository -> assignExecutor - Ended") }

        let token = try await getValidToken()
        let body = APIConfig.RequesterAssignTaskBody(executorId: executorId)
        let config = APIConfig.requesterAssignTask(id: taskId, body: body, accessToken: token)
        let response: APIResponseDTO<EmptyDataDTO> = try await network.request(config)

        return (message: response.message, type: response.type)
    }

    /// Initiates a new payment attempt for a task and returns the payment URL.
    ///
    /// - Parameter taskId: The task's ID.
    /// - Returns: The payment `URL` to open (e.g. in a `WebView`).
    /// - Throws: A networking error, ``AuthError/noSession``, or
    ///   ``PaymentError/invalidPaymentURL(received:)`` if the server returns
    ///   a `paymentUrl` string that doesn't parse as a `URL`.
    func startPayment(taskId: String) async throws -> URL {
        DebugLogger.log("💳 🟢 TaskRepository -> startPayment - Started")
        defer { DebugLogger.log("💳 🏁 TaskRepository -> startPayment - Ended") }

        let token = try await getValidToken()
        let config = APIConfig.initiatePayment(taskId: taskId, accessToken: token)
        let response: APIResponseDTO<PaymentResponseDTO> = try await network.request(config)

        guard let url = URL(string: response.data.paymentUrl) else {
            DebugLogger.log("❌ startPayment received an invalid paymentUrl: \(response.data.paymentUrl)")
            throw PaymentError.invalidPaymentURL(received: response.data.paymentUrl)
        }

        return url
    }

    /// Declines an applicant for a task (requester-only).
    ///
    /// - Parameters:
    ///   - taskId: The task's ID.
    ///   - applicantId: The applicant's user ID to decline.
    /// - Returns: A tuple of a server message and message type.
    /// - Throws: A networking error, or ``AuthError/noSession``.
    func declineApplicant(taskId: String, applicantId: String) async throws -> (message: String, type: String) {
        DebugLogger.log("❌ 🟢 TaskRepository -> declineApplicant - Started")
        defer { DebugLogger.log("❌ 🏁 TaskRepository -> declineApplicant - Ended") }

        let token = try await getValidToken()
        let config = APIConfig.requesterDeclineApplicant(taskId: taskId, applicantId: applicantId, accessToken: token)
        let response: APIResponseDTO<EmptyDataDTO> = try await network.request(config)

        return (message: response.message, type: response.type)
    }

    // MARK: - Executor Actions

    /// Applies to a task as an executor.
    ///
    /// - Parameters:
    ///   - id: The task's ID.
    ///   - proposedBudget: An optional counter-offer budget.
    /// - Returns: A tuple of a server message and message type.
    /// - Throws: A networking error, or ``AuthError/noSession``.
    func applyToTask(id: String, proposedBudget: Double?) async throws -> (message: String, type: String) {
        DebugLogger.log("✋ 🟢 TaskRepository -> applyToTask - Started")
        defer { DebugLogger.log("✋ 🏁 TaskRepository -> applyToTask - Ended") }

        let token = try await getValidToken()
        let body = APIConfig.ExecutorApplyTaskBody(proposedBudget: proposedBudget)
        let config = APIConfig.executorApplyTask(id: id, body: body, accessToken: token)
        let response: APIResponseDTO<EmptyDataDTO> = try await network.request(config)

        return (message: response.message, type: response.type)
    }

    /// Withdraws the executor from an assigned task.
    ///
    /// Withdrawals are subject to a strike policy (3 withdrawals within 7
    /// days trigger a temporary suspension); the response indicates whether
    /// this withdrawal triggered a suspension and/or warning.
    ///
    /// - Parameter id: The task's ID.
    /// - Returns: A ``WithdrawResult`` with a server message, message type,
    ///   `suspended` flag, and optional `warning`.
    /// - Throws: A networking error, or ``AuthError/noSession``.
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

    /// Marks an assigned task as done (executor-only).
    ///
    /// - Parameter id: The task's ID.
    /// - Returns: A tuple of a server message and message type.
    /// - Throws: A networking error, or ``AuthError/noSession``.
    func markTaskDone(id: String) async throws -> (message: String, type: String) {
        DebugLogger.log("✔️ 🟢 TaskRepository -> markTaskDone - Started")
        defer { DebugLogger.log("✔️ 🏁 TaskRepository -> markTaskDone - Ended") }

        let token = try await getValidToken()
        let config = APIConfig.executorMarkDone(id: id, accessToken: token)
        let response: APIResponseDTO<EmptyDataDTO> = try await network.request(config)

        return (message: response.message, type: response.type)
    }

    /// Favorites a task (executor-only).
    ///
    /// - Parameter id: The task's ID.
    /// - Returns: A tuple of a server message and message type.
    /// - Throws: A networking error, or ``AuthError/noSession``.
    func favoriteTask(id: String) async throws -> (message: String, type: String) {
        DebugLogger.log("❤️ 🟢 TaskRepository -> favoriteTask - Started")
        defer { DebugLogger.log("❤️ 🏁 TaskRepository -> favoriteTask - Ended") }

        let token = try await getValidToken()
        let config = APIConfig.executorFavoriteTask(id: id, accessToken: token)
        let response: APIResponseDTO<EmptyDataDTO> = try await network.request(config)

        return (message: response.message, type: response.type)
    }

    /// Removes a task from favorites (executor-only).
    ///
    /// - Parameter id: The task's ID.
    /// - Returns: A tuple of a server message and message type.
    /// - Throws: A networking error, or ``AuthError/noSession``.
    func unfavoriteTask(id: String) async throws -> (message: String, type: String) {
        DebugLogger.log("💔 🟢 TaskRepository -> unfavoriteTask - Started")
        defer { DebugLogger.log("💔 🏁 TaskRepository -> unfavoriteTask - Ended") }

        let token = try await getValidToken()
        let config = APIConfig.executorUnfavoriteTask(id: id, accessToken: token)
        let response: APIResponseDTO<EmptyDataDTO> = try await network.request(config)

        return (message: response.message, type: response.type)
    }

    // MARK: - Rating Actions

    /// Rates the executor of a completed task (requester-only).
    ///
    /// - Parameters:
    ///   - taskId: The task's ID.
    ///   - rating: The rating value (e.g. 1–5).
    ///   - comment: A rating comment.
    /// - Returns: A tuple of a server message and message type.
    /// - Throws: A networking error, or ``AuthError/noSession``.
    func rateExecutor(taskId: String, rating: Int, comment: String) async throws -> (message: String, type: String) {
        DebugLogger.log("🌟 🟢 TaskRepository -> rateExecutor - Started")
        defer { DebugLogger.log("🌟 🏁 TaskRepository -> rateExecutor - Ended") }

        let token = try await getValidToken()
        let body = APIConfig.RatingBody(rating: rating, comment: comment)
        let config = APIConfig.requesterRateExecutor(id: taskId, body: body, accessToken: token)
        let response: APIResponseDTO<EmptyDataDTO> = try await network.request(config)
        return (message: response.message, type: response.type)
    }

    /// Rates the requester of a completed task (executor-only).
    ///
    /// - Parameters:
    ///   - taskId: The task's ID.
    ///   - rating: The rating value (e.g. 1–5).
    ///   - comment: A rating comment.
    /// - Returns: A tuple of a server message and message type.
    /// - Throws: A networking error, or ``AuthError/noSession``.
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
