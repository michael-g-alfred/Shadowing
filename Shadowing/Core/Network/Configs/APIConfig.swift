import Foundation
import MGNetworkingKit

/// Namespace for building ``MGRequestConfig`` values for every endpoint the app calls.
///
/// Each feature area (Auth, Users, Executor, Requester, ...) is implemented as
/// a separate `extension APIConfig` in its own file. This file holds the
/// shared helpers and body types used across more than one feature area.
enum APIConfig {
    
        // MARK: - Helpers
    
    /// Builds a `[URLQueryItem]` array from a list of optional name/value pairs,
    /// dropping any pair whose value is `nil`.
    ///
    /// - Parameter items: The candidate query items, where a `nil` value means
    ///   "omit this parameter".
    /// - Returns: The resolved query items, or `nil` if none of the values were present.
    static func queryItems(_ items: [(name: String, value: String?)]) -> [URLQueryItem]? {
        var components = URLComponents()
        components.queryItems = items.compactMap { (name: String, value: String?) -> URLQueryItem? in
            guard let value else { return nil }
            return URLQueryItem(name: name, value: value)
        }
        guard let resolved = components.queryItems, !resolved.isEmpty else { return nil }
        return resolved
    }
    
    /// Builds the standard header set used by every request in the app.
    ///
    /// Always includes `Accept-Language` derived from ``LanguageManager``.
    /// Adds `Authorization` when `accessToken` is provided, and `Content-Type`
    /// when `contentType` is provided.
    ///
    /// - Parameters:
    ///   - accessToken: The bearer token to attach, or `nil` for unauthenticated requests.
    ///   - contentType: The `Content-Type` header value to attach, or `nil` to omit it.
    /// - Returns: The resolved header dictionary.
    static func requestHeaders(accessToken: String?, contentType: String? = nil) -> [String: String] {
        var headers: [String: String] = [
            "Accept-Language": {
                switch LanguageManager.shared.currentLanguage {
                    case .arabic:  return "ar"
                    case .french:  return "fr"
                    default:       return "en"
                }
            }(),
        ]
        if let accessToken {
            headers["Authorization"] = "Bearer \(accessToken)"
        }
        if let contentType {
            headers["Content-Type"] = contentType
        }
        return headers
    }
    
    /// The shared request body for rating either a requester or an executor.
    ///
    /// - Note: Conforms to `Sendable` so it can be wrapped in ``MGAnyEncodable``
    ///   and passed as a `.json` ``MGRequestBody``.
    nonisolated struct RatingBody: Encodable, Sendable {
        let rating: Int
        let comment: String
    }
}
