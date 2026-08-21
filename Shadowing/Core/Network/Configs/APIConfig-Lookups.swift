import Foundation
import MGNetworkingKit

extension APIConfig {
    
        // MARK: - Lookups
    
    /// Builds the request that fetches every lookup list (countries, specialties, etc.) at once.
    ///
    /// - Returns: A configured, unauthenticated `GET` request.
    static func lookups() -> MGRequestConfig {
        MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.lookupPath,
            method: .get,
            headers: self.requestHeaders(accessToken: nil)
        )
    }
    
    /// Builds the request that fetches a single lookup list by type.
    ///
    /// - Parameter type: The lookup type to fetch, e.g. `"countries"` or `"specialties"`.
    /// - Returns: A configured, unauthenticated `GET` request.
    static func lookups(type: String) -> MGRequestConfig {
        MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.lookupTypePath(type: type),
            method: .get,
            headers: self.requestHeaders(accessToken: nil)
        )
    }
}
