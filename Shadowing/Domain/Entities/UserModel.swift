import Foundation

struct UserModel: Codable, Identifiable, Equatable, Profile {
    let id: String
    let email: String
    let displayName: String
    let nationalId: String?
    let avatarUrl: String?
    let role: String
    let rating: Double
    let totalRatings: Int
    let completedTasks: Int
    let createdAt: Date?
    
    var isAdmin: Bool { role.lowercased() == "admin" }
}

extension UserModel {
    func withAvatarUrl(_ url: String) -> UserModel {
        UserModel(
            id: id,
            email: email,
            displayName: displayName,
            nationalId: nationalId,
            avatarUrl: url,
            role: role,
            rating: rating,
            totalRatings: totalRatings,
            completedTasks: completedTasks,
            createdAt: createdAt
        )
    }
}
