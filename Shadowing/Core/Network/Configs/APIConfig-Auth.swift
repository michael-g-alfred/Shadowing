import Foundation
import MGNetworkingKit

extension APIConfig {
    
        // MARK: - Auth
    
    struct SignupBody: Encodable, Sendable {
        let email: String
        let password: String
        let displayName: String
        let nationalId: String
        let countryId: Int
        let governorateId: Int
        let bio: String
        let specialtyIds: [Int]
    }
    
    static func signup(_ body: SignupBody) -> MGRequestConfig {
        MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.signupPath,
            method: .post,
            headers: self.requestHeaders(accessToken: nil),
            body: body
        )
    }
    
    struct SigninBody: Encodable, Sendable {
        let email: String
        let password: String
    }
    
    static func signin(_ body: SigninBody) -> MGRequestConfig {
        MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.signinPath,
            method: .post,
            headers: self.requestHeaders(accessToken: nil),
            body: body
        )
    }
    
    struct RefreshTokenBody: Codable, Sendable {
        let refreshToken: String
    }
    
    static func signout(_ body: RefreshTokenBody) -> MGRequestConfig {
        MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.signoutPath,
            method: .post,
            headers: self.requestHeaders(accessToken: nil),
            body: body
        )
    }
    
    static func refresh(_ body: RefreshTokenBody) -> MGRequestConfig {
        MGRequestConfig(
            baseURL: APIEndpoints.baseURL,
            path: APIEndpoints.refreshPath,
            method: .post,
            headers: self.requestHeaders(accessToken: nil),
            body: body
        )
    }
}
