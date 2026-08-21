import Foundation
import MGNetworkingKit

extension APIConfig {
    
        // MARK: - Users
    
    /// Builds the request that fetches the total number of registered users.
    ///
    /// - Parameter accessToken: The requesting user's bearer token.
    /// - Returns: A configured, authenticated `GET` request.
    static func userCount(accessToken: String) -> MGRequestConfig {
        MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.userCountPath,
            method: .get,
            headers: Self.requestHeaders(accessToken: accessToken)
        )
    }
    
    /// Builds the request that fetches a user's full profile.
    ///
    /// - Parameters:
    ///   - id: The identifier of the user to fetch.
    ///   - accessToken: The requesting user's bearer token.
    /// - Returns: A configured, authenticated `GET` request.
    static func user(id: String, accessToken: String) -> MGRequestConfig {
        MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.userPath(id: id),
            method: .get,
            headers: Self.requestHeaders(accessToken: accessToken)
        )
    }
    
    /// Builds the request that fetches a condensed summary of a user's profile.
    ///
    /// - Parameters:
    ///   - id: The identifier of the user to fetch.
    ///   - accessToken: The requesting user's bearer token.
    /// - Returns: A configured, authenticated `GET` request.
    static func userSummary(id: String, accessToken: String) -> MGRequestConfig {
        MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.userSummaryPath(id: id),
            method: .get,
            headers: Self.requestHeaders(accessToken: accessToken)
        )
    }
    
    /// Builds the request that uploads a new avatar image for a user.
    ///
    /// - Parameters:
    ///   - userId: The identifier of the user whose avatar is being updated.
    ///   - imageData: The raw image bytes to upload.
    ///   - fileName: The file name reported for the uploaded image, e.g. `"avatar.jpg"`.
    ///   - mimeType: The MIME type of `imageData`, e.g. `"image/jpeg"`.
    ///   - accessToken: The requesting user's bearer token.
    /// - Returns: A configured, authenticated `POST` request with a multipart/form-data body.
    static func uploadAvatar(userId: String, imageData: Data, fileName: String, mimeType: String, accessToken: String) -> MGRequestConfig {
        var multipart = MGMultipartFormData()
        
        multipart.appendFile(
            fieldName: "avatar",
            fileName: fileName,
            mimeType: mimeType,
            data: imageData
        )
        
        return MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.userAvatarPath(id: userId),
            method: .post,
            headers: Self.requestHeaders(
                accessToken: accessToken
            ),
            body: .multipart(multipart)
        )
    }
    
    /// Builds the request that lists the ratings left for a user.
    ///
    /// - Parameters:
    ///   - userId: The identifier of the rated user.
    ///   - cursor: The pagination cursor, or `nil` for the first page.
    ///   - limit: The maximum number of items to return, or `nil` for the server default.
    ///   - accessToken: The requesting user's bearer token.
    /// - Returns: A configured, authenticated `GET` request.
    static func userRatings(userId: String, cursor: String?, limit: Int?, accessToken: String) -> MGRequestConfig {
        return MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.userRatingsPath(id: userId),
            method: .get,
            queryItems: Self.queryItems([
                ("cursor", cursor),
                ("limit", limit.map { "\($0)" }),
            ]),
            headers: Self.requestHeaders(accessToken: accessToken)
        )
    }
    
    /// Builds the request that lists users offering a given specialty/service type.
    ///
    /// - Parameters:
    ///   - serviceId: The identifier of the service type to filter by.
    ///   - limit: The maximum number of items to return, or `nil` for the server default.
    ///   - accessToken: The requesting user's bearer token.
    /// - Returns: A configured, authenticated `GET` request.
    static func usersBySpecialty(serviceId: Int, limit: Int? = nil, accessToken: String) -> MGRequestConfig {
        MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.usersBySpecialtyPath(serviceId: serviceId),
            method: .get,
            queryItems: Self.queryItems([
                ("limit", limit.map { "\($0)" })
            ]),
            headers: Self.requestHeaders(accessToken: accessToken)
        )
    }
    
    /// Builds the request that updates a user's profile.
    ///
    /// - Parameters:
    ///   - userId: The identifier of the user to update.
    ///   - payload: The profile fields to update.
    ///   - accessToken: The requesting user's bearer token.
    /// - Returns: A configured, authenticated `PATCH` request.
    ///
    /// - Note: `payload` is passed directly as a `.json` body rather than being
    ///   pre-encoded to `Data`; encoding happens once, inside ``MGNetworkService``,
    ///   which also lets any encoding failure surface as `NetworkError.encodingFailed`.
    static func updateProfile(userId: String, payload: EditProfilePayload, accessToken: String) -> MGRequestConfig {
        MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.userPath(id: userId),
            method: .patch,
            headers: Self.requestHeaders(accessToken: accessToken, contentType: "application/json"),
            body: .json(MGAnyEncodable(payload))
        )
    }
}
