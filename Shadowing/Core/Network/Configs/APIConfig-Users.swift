import Foundation
import MGNetworkingKit

extension APIConfig {
    
        // MARK: - Users
    
    static func userCount(accessToken: String) -> MGRequestConfig {
        MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.userCountPath,
            method: .get,
            headers: ["Authorization": "Bearer \(accessToken)"]
        )
    }
    
    static func user(id: String, accessToken: String) -> MGRequestConfig {
        MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.userPath(id: id),
            method: .get,
            headers: ["Authorization": "Bearer \(accessToken)"]
        )
    }
    
    static func uploadAvatar(userId: String, imageData: Data, fileName: String, mimeType: String, accessToken: String) -> MGRequestConfig {
        let boundary = UUID().uuidString
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"avatar\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        return MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.userAvatarPath(id: userId),
            method: .post,
            headers: [
                "Authorization": "Bearer \(accessToken)",
                "Content-Type": "multipart/form-data; boundary=\(boundary)"
            ],
            body: body
        )
    }
    
        // endpoint جديد لجلب تقييمات مستخدم معين
    static func userRatings(userId: String, cursor: String?, limit: Int?, accessToken: String) -> MGRequestConfig {
        var queryItems: [URLQueryItem] = []
        if let cursor { queryItems.append(URLQueryItem(name: "cursor", value: cursor)) }
        if let limit { queryItems.append(URLQueryItem(name: "limit", value: "\(limit)")) }
        
        return MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.userRatingsPath(id: userId),
            method: .get,
            queryItems: queryItems,
            headers: ["Authorization": "Bearer \(accessToken)"]
        )
    }
}
