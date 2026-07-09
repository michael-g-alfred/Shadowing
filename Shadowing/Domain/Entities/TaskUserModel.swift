import Foundation

struct TaskUserModel: Identifiable, Profile {
    let id: String
    let displayName: String
    let avatarUrl: String?
    let rating: Double
    let totalRatings: Int
    let completedTasks: Int
}
