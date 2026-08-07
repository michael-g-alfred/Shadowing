import Foundation

struct UserSummaryModel: Identifiable, Profile {
    let id: String
    let displayName: String
    let email: String?
    let avatarUrl: String?
    let bio: String?
    let rating: Double
    let totalRatings: Int
    let completedTasks: Int
    let specialties: [SpecialtyModel]
}
