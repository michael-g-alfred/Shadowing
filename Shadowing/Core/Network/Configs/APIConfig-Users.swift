import Foundation
import MGNetworkingKit

extension APIConfig {
    
        // MARK: - Users
    
    static func userCount(accessToken: String) -> MGRequestConfig {
        MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.userCountPath,
            method: .get,
            headers: Self.requestHeaders(accessToken: accessToken)
        )
    }
    
    static func user(id: String, accessToken: String) -> MGRequestConfig {
        MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.userPath(id: id),
            method: .get,
            headers: Self.requestHeaders(accessToken: accessToken)
        )
    }
    
    static func userSummary(id: String, accessToken: String) -> MGRequestConfig {
        MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.userSummaryPath(id: id),
            method: .get,
            headers: Self.requestHeaders(accessToken: accessToken)
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
            headers: Self.requestHeaders(accessToken: accessToken, contentType: "multipart/form-data; boundary=\(boundary)"),
            rawBody: body
        )
    }
    
    static func userRatings(userId: String, cursor: String?, limit: Int?, accessToken: String) -> MGRequestConfig {
        var queryItems: [URLQueryItem] = []
        if let cursor { queryItems.append(URLQueryItem(name: "cursor", value: cursor)) }
        if let limit { queryItems.append(URLQueryItem(name: "limit", value: "\(limit)")) }
        
        return MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.userRatingsPath(id: userId),
            method: .get,
            queryItems: queryItems,
            headers: Self.requestHeaders(accessToken: accessToken)
        )
    }
    
    static func usersBySpecialty(serviceId: Int, limit: Int? = nil, accessToken: String) -> MGRequestConfig {
        MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.usersBySpecialtyPath(serviceId: serviceId),
            method: .get,
            queryItems: Self.queryItems([
                ("limit", limit.map(String.init))
            ]),
            headers: Self.requestHeaders(accessToken: accessToken)
        )
    }
    
        /// PATCH /users/:id — partial profile update. `payload` only encodes
        /// the fields that were actually set (see EditProfilePayload), so this
        /// naturally sends a minimal, whitelisted body matching the backend's
        /// editProfileSchema.
    static func updateProfile(userId: String, payload: EditProfilePayload, accessToken: String) throws -> MGRequestConfig {
        let body = try JSONEncoder().encode(payload)
        return MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.userPath(id: userId),
            method: .patch,
            headers: Self.requestHeaders(accessToken: accessToken, contentType: "application/json"),
            rawBody: body
        )
    }
}
