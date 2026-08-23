import Foundation
import MGNetworkingKit

extension APIConfig {

    /// Shared factory for the common "paginated GET" shape used throughout
    /// `APIConfig-Executor.swift`, `APIConfig-Requester.swift`, and
    /// `APIConfig-Shared Tasks.swift`: a `cursor`/`limit` pair plus any
    /// endpoint-specific query items, an authenticated `GET` request.
    ///
    /// - Parameters:
    ///   - path: The endpoint path.
    ///   - cursor: The pagination cursor, or `nil` for the first page.
    ///   - limit: The maximum number of items to return, or `nil` for the
    ///     server default.
    ///   - additionalItems: Extra query items specific to this endpoint
    ///     (e.g. `status`, `lat`/`lng`, `favoritesOnly`), appended after
    ///     `cursor`/`limit`.
    ///   - accessToken: The requesting user's bearer token.
    /// - Returns: A configured, authenticated `GET` request.
    static func paginatedGetRequest(
        path: String,
        cursor: String?,
        limit: Int?,
        additionalItems: [(name: String, value: String?)] = [],
        accessToken: String
    ) -> MGRequestConfig {
        let items: [(name: String, value: String?)] =
            [("cursor", cursor), ("limit", limit.map { "\($0)" })] + additionalItems

        return MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: path,
            method: .get,
            queryItems: Self.queryItems(items),
            headers: Self.requestHeaders(accessToken: accessToken)
        )
    }
}
