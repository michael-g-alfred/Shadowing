import Foundation
import MGNetworkingKit

extension APIConfig {
    
        // MARK: - Shared Tasks
    
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
                ("limit", limit.map(String.init))
            ]),
            headers: Self.requestHeaders(accessToken: accessToken)
        )
    }
    
    static func taskDetails(id: String, accessToken: String) -> MGRequestConfig {
        MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.taskDetailsPath(id: id),
            method: .get,
            headers: Self.requestHeaders(accessToken: accessToken)
        )
    }
}
