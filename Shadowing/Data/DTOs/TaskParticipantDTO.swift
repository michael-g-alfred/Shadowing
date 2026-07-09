import Foundation

struct TaskParticipantDTO: Codable {
    let id: String
    let displayName: String
    let avatarUrl: String?
    let rating: Double
    let totalRatings: Int
    let completedTasks: Int
}

extension TaskParticipantDTO {
    func toDomain() -> TaskUserModel {
        TaskUserModel(
            id: id,
            displayName: displayName,
            avatarUrl: avatarUrl,
            rating: rating,
            totalRatings: totalRatings,
            completedTasks: completedTasks
        )
    }
}
