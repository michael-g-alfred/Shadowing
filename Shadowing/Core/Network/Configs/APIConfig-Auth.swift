import Foundation
import MGNetworkingKit

extension APIConfig {
    
        // MARK: - Auth
    
    /// The request body for creating a new account.
    nonisolated struct SignupBody: Encodable, Sendable {
        let email: String
        let password: String
        let displayName: String
        let nationalId: String
        let phoneCountryId: Int
        let phoneNumber: String
        let countryId: Int
        let governorateId: Int
        let bio: String
        let specialtyIds: [Int]
    }
    
    /// Builds the request that registers a new account.
    ///
    /// - Parameter body: The new account's details.
    /// - Returns: A configured, unauthenticated `POST` request.
    static func signup(_ body: SignupBody) -> MGRequestConfig {
        MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.signupPath,
            method: .post,
            headers: self.requestHeaders(accessToken: nil, contentType: "application/json"),
            body: .json(MGAnyEncodable(body))
        )
    }
    
    /// The request body for signing in with email and password.
    nonisolated struct SigninBody: Encodable, Sendable {
        let email: String
        let password: String
    }
    
    /// Builds the request that signs in an existing account.
    ///
    /// - Parameter body: The account's credentials.
    /// - Returns: A configured, unauthenticated `POST` request.
    static func signin(_ body: SigninBody) -> MGRequestConfig {
        MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.signinPath,
            method: .post,
            headers: self.requestHeaders(accessToken: nil, contentType: "application/json"),
            body: .json(MGAnyEncodable(body))
        )
    }
    
    /// The request body for operations that only require a refresh token.
    nonisolated struct RefreshTokenBody: Codable, Sendable {
        let refreshToken: String
    }
    
    /// Builds the request that signs out the current session.
    ///
    /// - Parameter body: The refresh token identifying the session to end.
    /// - Returns: A configured, unauthenticated `POST` request.
    static func signout(_ body: RefreshTokenBody) -> MGRequestConfig {
        MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.signoutPath,
            method: .post,
            headers: self.requestHeaders(accessToken: nil, contentType: "application/json"),
            body: .json(MGAnyEncodable(body))
        )
    }
    
    /// Builds the request that exchanges a refresh token for a new access token.
    ///
    /// - Parameter body: The refresh token to exchange.
    /// - Returns: A configured, unauthenticated `POST` request.
    static func refresh(_ body: RefreshTokenBody) -> MGRequestConfig {
        MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.refreshPath,
            method: .post,
            headers: self.requestHeaders(accessToken: nil, contentType: "application/json"),
            body: .json(MGAnyEncodable(body))
        )
    }
}
