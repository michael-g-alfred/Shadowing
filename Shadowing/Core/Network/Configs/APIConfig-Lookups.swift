import Foundation
import MGNetworkingKit

extension APIConfig {
    
        // MARK: - Lookups
    
    static func lookups(accessToken: String) -> MGRequestConfig {
        MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.lookupPath,
            method: .get,
            headers: ["Authorization": "Bearer \(accessToken)"]
        )
    }
    
    static func lookups(type: String, accessToken: String) -> MGRequestConfig {
        MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.lookupTypePath(type: type),
            method: .get,
            headers: ["Authorization": "Bearer \(accessToken)"]
        )
    }
}
