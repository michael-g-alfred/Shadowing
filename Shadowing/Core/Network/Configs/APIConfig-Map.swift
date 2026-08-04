import Foundation
import MGNetworkingKit

extension APIConfig {
    
        // MARK: - Map
    
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
