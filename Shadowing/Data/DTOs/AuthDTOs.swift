import Foundation

struct AuthResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let user: UserModel
    /// Firebase custom token minted by the backend, used to bridge our
    /// Node/Postgres session into Firebase Auth so Firestore security rules
    /// can authorize by `request.auth.uid`. Optional so the client keeps
    /// working if the backend hasn't started sending it yet.
    let firebaseToken: String?
}

struct RefreshResponse: Codable {
    let accessToken: String
    let user: UserModel
    /// See ``AuthResponse/firebaseToken``.
    let firebaseToken: String?
}
