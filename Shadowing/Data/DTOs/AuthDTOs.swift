import Foundation

struct AuthResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let user: UserModel
    let firebaseToken: String?
}

struct RefreshResponse: Codable {
    let accessToken: String
    let user: UserModel
    /// See ``AuthResponse/firebaseToken``.
    let firebaseToken: String?
}
