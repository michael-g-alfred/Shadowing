import Foundation
import MGNetworkingKit

extension APIConfig {
    
        // MARK: - Map
    
    static func mapTasks(
        cursor: String? = nil,
        limit: Int? = nil,
        accessToken: String
    ) -> MGRequestConfig {
        MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.mapTasksPath,
            method: .get,
            queryItems: Self.queryItems([
                ("cursor", cursor),
                ("limit", limit.map(String.init))
            ]),
            headers: ["Authorization": "Bearer \(accessToken)"]
        )
    }
}
