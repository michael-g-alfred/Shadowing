import Foundation

struct UserSummaryResponseDTO: Codable {
    let user: UserSummaryDTO
}

struct UserSummaryDTO: Codable {
    let id: String
    let displayName: String
    let email: String?
    let avatarUrl: String?
    let bio: String?
    let rating: Double
    let totalRatings: Int
    let completedTasks: Int
    let specialties: [SpecialtyModel]?
}

extension UserSummaryDTO {
    func toDomain() -> UserSummaryModel {
        UserSummaryModel(
            id: id,
            displayName: displayName,
            email: email,
            avatarUrl: avatarUrl,
            bio: bio,
            rating: rating,
            totalRatings: totalRatings,
            completedTasks: completedTasks,
            specialties: specialties ?? []
        )
    }
}
