import Foundation

struct UserModel: Codable, Identifiable, Equatable, Profile {
    let id: String
    let email: String
    let displayName: String
    let nationalId: String?
    var avatarUrl: String?
    let role: String
    let rating: Double
    let totalRatings: Int
    let completedTasks: Int
    let accountStatus: String
    let suspendedUntil: Date?
    let countryId: Int?
    let governorateId: Int?
    let createdAt: Date?

    var isAdmin: Bool { role.lowercased() == "admin" }
    var isSuspended: Bool { accountStatus == "suspended" }
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
            accountStatus: accountStatus,
            suspendedUntil: suspendedUntil,
            countryId: countryId,
            governorateId: governorateId,
            createdAt: createdAt
        )
    }
}
