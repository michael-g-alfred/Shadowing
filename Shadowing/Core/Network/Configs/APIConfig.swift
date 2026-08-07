import Foundation
import MGNetworkingKit

enum APIConfig {
    
        // MARK: - Helpers
    
    static func queryItems(_ items: [(name: String, value: String?)]) -> [URLQueryItem]? {
        var components = URLComponents()
        components.queryItems = items.compactMap { (name: String, value: String?) -> URLQueryItem? in
            guard let value else { return nil }
            return URLQueryItem(name: name, value: value)
        }
        guard let resolved = components.queryItems, !resolved.isEmpty else { return nil }
        return resolved
    }
    
    static func requestHeaders(accessToken: String?, contentType: String? = nil) -> [String: String] {
        var headers: [String: String] = [
            "Accept-Language": LanguageManager.shared.currentLanguage == .arabic ? "ar" : "en",
        ]
        if let accessToken {
            headers["Authorization"] = "Bearer \(accessToken)"
        }
        if let contentType {
            headers["Content-Type"] = contentType
        }
        return headers
    }
    
    struct RatingBody: Encodable {
        let rating: Int
        let comment: String
    }
}
