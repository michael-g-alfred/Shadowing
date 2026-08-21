import Foundation
import MGNetworkingKit

extension APIConfig {
    
        // MARK: - Public
    
    /// Builds the request that checks whether the API is reachable and healthy.
    ///
    /// - Returns: A configured, unauthenticated `GET` request.
    static func healthCheck() -> MGRequestConfig {
        MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.healthCheckPath,
            method: .get,
            headers: self.requestHeaders(accessToken: nil)
        )
    }
}
