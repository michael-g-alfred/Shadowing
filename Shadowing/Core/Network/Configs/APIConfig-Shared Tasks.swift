import Foundation
import MGNetworkingKit

extension APIConfig {
    
        // MARK: - Shared Tasks
    
    /// Builds the request that lists all tasks visible to the current user,
    /// regardless of role.
    ///
    /// - Parameters:
    ///   - cursor: The pagination cursor, or `nil` for the first page.
    ///   - limit: The maximum number of items to return, or `nil` for the server default.
    ///   - accessToken: The requesting user's bearer token.
    /// - Returns: A configured, authenticated `GET` request.
    static func allTasks(
        cursor: String? = nil,
        limit: Int? = nil,
        accessToken: String
    ) -> MGRequestConfig {
        MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.allTasksPath,
            method: .get,
            queryItems: Self.queryItems([
                ("cursor", cursor),
                ("limit", limit.map { "\($0)" })
            ]),
            headers: Self.requestHeaders(accessToken: accessToken)
        )
    }
    
    /// Builds the request that fetches the full details of a single task.
    ///
    /// - Parameters:
    ///   - id: The identifier of the task to fetch.
    ///   - accessToken: The requesting user's bearer token.
    /// - Returns: A configured, authenticated `GET` request.
    static func taskDetails(id: String, accessToken: String) -> MGRequestConfig {
        MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.taskDetailsPath(id: id),
            method: .get,
            headers: Self.requestHeaders(accessToken: accessToken)
        )
    }
}
