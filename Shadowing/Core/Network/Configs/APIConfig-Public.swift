import Foundation
import MGNetworkingKit

extension APIConfig {
    
        // MARK: - Public
    
    static func healthCheck() -> MGRequestConfig {
        MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.healthCheckPath,
            method: .get,
            headers: self.requestHeaders(accessToken: nil),
        )
    }
}
