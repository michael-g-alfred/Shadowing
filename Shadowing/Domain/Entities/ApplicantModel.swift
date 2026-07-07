import Foundation

struct ApplicantModel: Identifiable, Profile {
    let id: String
    let displayName: String
    let rating: Double?
    let completedTasks: Int
    let appliedAt: Date
    let proposedBudget: Double?
}
