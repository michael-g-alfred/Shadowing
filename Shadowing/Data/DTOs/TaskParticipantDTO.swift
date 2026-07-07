import Foundation

struct TaskParticipantDTO: Codable {
    let id: String
    let displayName: String
    let rating: Double
    let totalRatings: Int
    let completedTasks: Int
}

extension TaskParticipantDTO {
    func toDomain() -> TaskUserModel {
        TaskUserModel(
            id: id,
            displayName: displayName,
            rating: rating,
            totalRatings: totalRatings,
            completedTasks: completedTasks
        )
    }
}
