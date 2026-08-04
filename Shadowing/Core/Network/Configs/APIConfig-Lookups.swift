import Foundation
import MGNetworkingKit

extension APIConfig {
    
        // MARK: - Lookups
    
    static func lookups() -> MGRequestConfig {
        MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.lookupPath,
            method: .get
        )
    }
    
    static func lookups(type: String) -> MGRequestConfig {
        MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.lookupTypePath(type: type),
            method: .get
        )
    }
}
