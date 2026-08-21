import Foundation
import MGNetworkingKit

extension APIConfig {
    
        // MARK: - Requester
    
    /// Builds the request that lists tasks a requester has published.
    ///
    /// - Parameters:
    ///   - cursor: The pagination cursor, or `nil` for the first page.
    ///   - limit: The maximum number of items to return, or `nil` for the server default.
    ///   - status: An optional status filter to apply.
    ///   - accessToken: The requesting user's bearer token.
    /// - Returns: A configured, authenticated `GET` request.
    static func requesterPublishedTasks(
        cursor: String? = nil,
        limit: Int? = nil,
        status: String? = nil,
        accessToken: String
    ) -> MGRequestConfig {
        MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.requesterPublishedTasksPath,
            method: .get,
            queryItems: Self.queryItems([
                ("cursor", cursor),
                ("limit", limit.map { "\($0)" }),
                ("status", status)
            ]),
            headers: Self.requestHeaders(accessToken: accessToken)
        )
    }
    
    /// Builds the request that lists tasks a requester has completed.
    ///
    /// - Parameters:
    ///   - cursor: The pagination cursor, or `nil` for the first page.
    ///   - limit: The maximum number of items to return, or `nil` for the server default.
    ///   - accessToken: The requesting user's bearer token.
    /// - Returns: A configured, authenticated `GET` request.
    static func requesterCompletedTasks(
        cursor: String? = nil,
        limit: Int? = nil,
        accessToken: String
    ) -> MGRequestConfig {
        MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.requesterCompletedTasksPath,
            method: .get,
            queryItems: Self.queryItems([
                ("cursor", cursor),
                ("limit", limit.map { "\($0)" })
            ]),
            headers: Self.requestHeaders(accessToken: accessToken)
        )
    }
    
    /// Builds the request that lists a requester's completed tasks that haven't been rated yet.
    ///
    /// - Parameters:
    ///   - cursor: The pagination cursor, or `nil` for the first page.
    ///   - limit: The maximum number of items to return, or `nil` for the server default.
    ///   - accessToken: The requesting user's bearer token.
    /// - Returns: A configured, authenticated `GET` request.
    static func requesterUnratedTasks(
        cursor: String? = nil,
        limit: Int? = nil,
        accessToken: String
    ) -> MGRequestConfig {
        MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.requesterUnratedTasksPath,
            method: .get,
            queryItems: Self.queryItems([
                ("cursor", cursor),
                ("limit", limit.map { "\($0)" })
            ]),
            headers: Self.requestHeaders(accessToken: accessToken)
        )
    }
    
    /// The request body for creating a new task.
    nonisolated struct RequesterCreateTaskBody: Codable, Sendable {
        let title: String
        let description: String
        let budget: Double
        let serviceTypeId: Int
        let address: String
        var currencyId: Int? = 1
        var priorityId: Int? = nil
        var latitude: Double?
        var longitude: Double?
        var scheduledAt: Date?
        var preferredTimeOfDayId: Int?
    }
    
    /// Builds the request that creates a new task.
    ///
    /// - Parameters:
    ///   - body: The new task's details.
    ///   - accessToken: The requesting user's bearer token.
    /// - Returns: A configured, authenticated `POST` request.
    static func requesterCreateTask(
        _ body: RequesterCreateTaskBody,
        accessToken: String
    ) -> MGRequestConfig {
        MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.requesterCreateTaskPath,
            method: .post,
            headers: Self.requestHeaders(accessToken: accessToken, contentType: "application/json"),
            body: .json(MGAnyEncodable(body))
        )
    }
    
    /// Builds the request that deletes a task.
    ///
    /// - Parameters:
    ///   - id: The identifier of the task to delete.
    ///   - accessToken: The requesting user's bearer token.
    /// - Returns: A configured, authenticated `DELETE` request.
    static func requesterDeleteTask(id: String, accessToken: String) -> MGRequestConfig {
        MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.requesterDeleteTaskPath(id: id),
            method: .delete,
            headers: Self.requestHeaders(accessToken: accessToken)
        )
    }
    
    /// Builds the request that cancels a task.
    ///
    /// - Parameters:
    ///   - id: The identifier of the task to cancel.
    ///   - accessToken: The requesting user's bearer token.
    /// - Returns: A configured, authenticated `PATCH` request.
    static func requesterCancelTask(id: String, accessToken: String) -> MGRequestConfig {
        MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.requesterCancelTaskPath(id: id),
            method: .patch,
            headers: Self.requestHeaders(accessToken: accessToken)
        )
    }
    
    /// Builds the request that publishes a draft task, making it visible to executors.
    ///
    /// - Parameters:
    ///   - id: The identifier of the task to publish.
    ///   - accessToken: The requesting user's bearer token.
    /// - Returns: A configured, authenticated `PATCH` request.
    static func requesterPublishTask(id: String, accessToken: String) -> MGRequestConfig {
        MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.requesterPublishTaskPath(id: id),
            method: .patch,
            headers: Self.requestHeaders(accessToken: accessToken)
        )
    }
    
    /// Builds the request that confirms a task, e.g. after an executor marks it done.
    ///
    /// - Parameters:
    ///   - id: The identifier of the task to confirm.
    ///   - accessToken: The requesting user's bearer token.
    /// - Returns: A configured, authenticated `PATCH` request.
    static func requesterConfirmTask(id: String, accessToken: String) -> MGRequestConfig {
        MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.requesterConfirmTaskPath(id: id),
            method: .patch,
            headers: Self.requestHeaders(accessToken: accessToken)
        )
    }
    
    /// Builds the request that lists the executors who applied to a task.
    ///
    /// - Parameters:
    ///   - id: The identifier of the task.
    ///   - accessToken: The requesting user's bearer token.
    /// - Returns: A configured, authenticated `GET` request.
    static func requesterApplicants(id: String, accessToken: String) -> MGRequestConfig {
        MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.requesterApplicantsPath(id: id),
            method: .get,
            headers: Self.requestHeaders(accessToken: accessToken)
        )
    }
    
    /// The request body for assigning a task to an executor.
    nonisolated struct RequesterAssignTaskBody: Encodable, Sendable {
        let executorId: String
    }
    
    /// Builds the request that assigns a task to a chosen executor.
    ///
    /// - Parameters:
    ///   - id: The identifier of the task to assign.
    ///   - body: The identifier of the executor to assign the task to.
    ///   - accessToken: The requesting user's bearer token.
    /// - Returns: A configured, authenticated `PATCH` request.
    static func requesterAssignTask(
        id: String,
        body: RequesterAssignTaskBody,
        accessToken: String
    ) -> MGRequestConfig {
        MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.requesterAssignTaskPath(id: id),
            method: .patch,
            headers: Self.requestHeaders(accessToken: accessToken, contentType: "application/json"),
            body: .json(MGAnyEncodable(body))
        )
    }
    
    /// Builds the request that declines an executor's application to a task.
    ///
    /// - Parameters:
    ///   - taskId: The identifier of the task.
    ///   - applicantId: The identifier of the executor whose application is declined.
    ///   - accessToken: The requesting user's bearer token.
    /// - Returns: A configured, authenticated `DELETE` request.
    static func requesterDeclineApplicant(
        taskId: String,
        applicantId: String,
        accessToken: String
    ) -> MGRequestConfig {
        MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.requesterDeclineApplicantPath(taskId: taskId, applicantId: applicantId),
            method: .delete,
            headers: Self.requestHeaders(accessToken: accessToken)
        )
    }
    
    /// Builds the request that submits a requester's rating of the executor for a completed task.
    ///
    /// - Parameters:
    ///   - id: The identifier of the completed task.
    ///   - body: The rating and comment to submit.
    ///   - accessToken: The requesting user's bearer token.
    /// - Returns: A configured, authenticated `POST` request.
    static func requesterRateExecutor(
        id: String,
        body: RatingBody,
        accessToken: String
    ) -> MGRequestConfig {
        MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.requesterRateExecutorPath(id: id),
            method: .post,
            headers: Self.requestHeaders(accessToken: accessToken, contentType: "application/json"),
            body: .json(MGAnyEncodable(body))
        )
    }
}
