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
    let accountStatus: AccountStatus
    let suspendedUntil: Date?
    let country: Country?
    let governorate: Governorate?
    let createdAt: Date?
    
    var isAdmin: Bool { role.lowercased() == "admin" }
    var isSuspended: Bool { accountStatus == .suspended }
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
            country: country,
            governorate: governorate,
            createdAt: createdAt
        )
    }
}
