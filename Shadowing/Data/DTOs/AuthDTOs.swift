import Foundation

struct AuthResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let user: UserModel
}

struct RefreshResponse: Codable {
    let accessToken: String
    let user: UserModel
}
