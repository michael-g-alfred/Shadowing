import Foundation

struct UserSummaryDTO: Codable {
    let id: String
    let displayName: String
    let avatarUrl: String?
    let rating: Double
    let totalRatings: Int
    let completedTasks: Int
}

extension UserSummaryDTO {
    func toDomain() -> UserSummaryModel {
        UserSummaryModel(
            id: id,
            displayName: displayName,
            avatarUrl: avatarUrl,
            rating: rating,
            totalRatings: totalRatings,
            completedTasks: completedTasks
        )
    }
}
