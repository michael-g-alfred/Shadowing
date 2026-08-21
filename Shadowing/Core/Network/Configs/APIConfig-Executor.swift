import Foundation
import MGNetworkingKit

extension APIConfig {
    
        // MARK: - Executor
    
    /// Builds the request that lists tasks available for an executor to apply to.
    ///
    /// - Parameters:
    ///   - cursor: The pagination cursor, or `nil` for the first page.
    ///   - limit: The maximum number of items to return, or `nil` for the server default.
    ///   - lat: The latitude to bias results toward, or `nil` to omit location filtering.
    ///   - lng: The longitude to bias results toward, or `nil` to omit location filtering.
    ///   - favoritesOnly: Whether to only return tasks the executor has favorited. Defaults to `false`.
    ///   - accessToken: The requesting executor's bearer token.
    /// - Returns: A configured, authenticated `GET` request.
    static func executorAvailableTasks(
        cursor: String? = nil,
        limit: Int? = nil,
        lat: Double? = nil,
        lng: Double? = nil,
        favoritesOnly: Bool = false,
        accessToken: String
    ) -> MGRequestConfig {
        let items: [(name: String, value: String?)] = [
            ("cursor", cursor),
            ("limit", limit.map { "\($0)" }),
            ("lat", lat.map { "\($0)" }),
            ("lng", lng.map { "\($0)" }),
            ("favoritesOnly", favoritesOnly ? "true" : nil)
        ]
        return MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.executorAvailableTasksPath,
            method: .get,
            queryItems: Self.queryItems(items),
            headers: Self.requestHeaders(accessToken: accessToken)
        )
    }
    
    /// Builds the request that lists tasks currently assigned to an executor.
    ///
    /// - Parameters:
    ///   - cursor: The pagination cursor, or `nil` for the first page.
    ///   - limit: The maximum number of items to return, or `nil` for the server default.
    ///   - accessToken: The requesting executor's bearer token.
    /// - Returns: A configured, authenticated `GET` request.
    static func executorAssignedTasks(
        cursor: String? = nil,
        limit: Int? = nil,
        accessToken: String
    ) -> MGRequestConfig {
        MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.executorAssignedTasksPath,
            method: .get,
            queryItems: Self.queryItems([
                ("cursor", cursor),
                ("limit", limit.map { "\($0)" })
            ]),
            headers: Self.requestHeaders(accessToken: accessToken)
        )
    }
    
    /// Builds the request that lists tasks an executor has completed.
    ///
    /// - Parameters:
    ///   - cursor: The pagination cursor, or `nil` for the first page.
    ///   - limit: The maximum number of items to return, or `nil` for the server default.
    ///   - accessToken: The requesting executor's bearer token.
    /// - Returns: A configured, authenticated `GET` request.
    static func executorCompletedTasks(
        cursor: String? = nil,
        limit: Int? = nil,
        accessToken: String
    ) -> MGRequestConfig {
        MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.executorCompletedTasksPath,
            method: .get,
            queryItems: Self.queryItems([
                ("cursor", cursor),
                ("limit", limit.map { "\($0)" })
            ]),
            headers: Self.requestHeaders(accessToken: accessToken)
        )
    }
    
    /// Builds the request that lists an executor's completed tasks that haven't been rated yet.
    ///
    /// - Parameters:
    ///   - cursor: The pagination cursor, or `nil` for the first page.
    ///   - limit: The maximum number of items to return, or `nil` for the server default.
    ///   - accessToken: The requesting executor's bearer token.
    /// - Returns: A configured, authenticated `GET` request.
    static func executorUnratedTasks(
        cursor: String? = nil,
        limit: Int? = nil,
        accessToken: String
    ) -> MGRequestConfig {
        MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.executorUnratedTasksPath,
            method: .get,
            queryItems: Self.queryItems([
                ("cursor", cursor),
                ("limit", limit.map { "\($0)" })
            ]),
            headers: Self.requestHeaders(accessToken: accessToken)
        )
    }
    
    /// The request body for an executor applying to a task.
    nonisolated struct ExecutorApplyTaskBody: Encodable, Sendable {
        var proposedBudget: Double? = nil
    }
    
    /// Builds the request that submits an executor's application to a task.
    ///
    /// - Parameters:
    ///   - id: The identifier of the task to apply to.
    ///   - body: The application details. Defaults to no proposed budget.
    ///   - accessToken: The requesting executor's bearer token.
    /// - Returns: A configured, authenticated `POST` request.
    static func executorApplyTask(
        id: String,
        body: ExecutorApplyTaskBody = .init(),
        accessToken: String
    ) -> MGRequestConfig {
        MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.executorApplyTaskPath(id: id),
            method: .post,
            headers: Self.requestHeaders(accessToken: accessToken, contentType: "application/json"),
            body: .json(MGAnyEncodable(body))
        )
    }
    
    /// Builds the request that withdraws an executor's application from a task.
    ///
    /// - Parameters:
    ///   - id: The identifier of the task to withdraw from.
    ///   - accessToken: The requesting executor's bearer token.
    /// - Returns: A configured, authenticated `DELETE` request.
    static func executorWithdrawTask(id: String, accessToken: String) -> MGRequestConfig {
        MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.executorWithdrawTaskPath(id: id),
            method: .delete,
            headers: Self.requestHeaders(accessToken: accessToken)
        )
    }
    
    /// Builds the request that marks an assigned task as done by the executor.
    ///
    /// - Parameters:
    ///   - id: The identifier of the task to mark as done.
    ///   - accessToken: The requesting executor's bearer token.
    /// - Returns: A configured, authenticated `PATCH` request.
    static func executorMarkDone(id: String, accessToken: String) -> MGRequestConfig {
        MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.executorMarkDonePath(id: id),
            method: .patch,
            headers: Self.requestHeaders(accessToken: accessToken)
        )
    }
    
    /// Builds the request that adds a task to the executor's favorites.
    ///
    /// - Parameters:
    ///   - id: The identifier of the task to favorite.
    ///   - accessToken: The requesting executor's bearer token.
    /// - Returns: A configured, authenticated `POST` request.
    static func executorFavoriteTask(id: String, accessToken: String) -> MGRequestConfig {
        MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.executorFavoriteTaskPath(id: id),
            method: .post,
            headers: Self.requestHeaders(accessToken: accessToken)
        )
    }
    
    /// Builds the request that removes a task from the executor's favorites.
    ///
    /// - Parameters:
    ///   - id: The identifier of the task to unfavorite.
    ///   - accessToken: The requesting executor's bearer token.
    /// - Returns: A configured, authenticated `DELETE` request.
    static func executorUnfavoriteTask(id: String, accessToken: String) -> MGRequestConfig {
        MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.executorFavoriteTaskPath(id: id),
            method: .delete,
            headers: Self.requestHeaders(accessToken: accessToken)
        )
    }
    
    /// Builds the request that submits an executor's rating of the requester for a completed task.
    ///
    /// - Parameters:
    ///   - id: The identifier of the completed task.
    ///   - body: The rating and comment to submit.
    ///   - accessToken: The requesting executor's bearer token.
    /// - Returns: A configured, authenticated `POST` request.
    static func executorRateRequester(
        id: String,
        body: RatingBody,
        accessToken: String
    ) -> MGRequestConfig {
        MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.executorRateRequesterPath(id: id),
            method: .post,
            headers: Self.requestHeaders(accessToken: accessToken, contentType: "application/json"),
            body: .json(MGAnyEncodable(body))
        )
    }
}
