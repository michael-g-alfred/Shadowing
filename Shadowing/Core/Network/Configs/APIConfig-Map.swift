import Foundation
import MGNetworkingKit

extension APIConfig {
    
        // MARK: - Map
    
    /// Builds the request that fetches tasks located within a map viewport.
    ///
    /// - Parameters:
    ///   - bounds: The visible map bounds to search within.
    ///   - accessToken: The requesting user's bearer token.
    /// - Returns: A configured, authenticated `GET` request.
    static func mapTasks(
        bounds: MapBounds,
        accessToken: String
    ) -> MGRequestConfig {
        MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.mapTasksPath,
            method: .get,
            queryItems: Self.queryItems([
                ("minLat", String(bounds.minLat)),
                ("maxLat", String(bounds.maxLat)),
                ("minLng", String(bounds.minLng)),
                ("maxLng", String(bounds.maxLng))
            ]),
            headers: Self.requestHeaders(accessToken: accessToken)
        )
    }
}
