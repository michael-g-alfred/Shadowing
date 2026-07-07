import Foundation

struct ApplicantsDataDTO: Codable {
    let applicants: [ApplicantDTO]
}

struct ApplicantDTO: Codable {
    let id: String
    let displayName: String
    let rating: Double?
    let completedTasks: Int
    let appliedAt: Date
    let proposedBudget: Double?
    
    func toDomain() -> ApplicantModel {
        ApplicantModel(
            id: id,
            displayName: displayName,
            rating: rating,
            completedTasks: completedTasks,
            appliedAt: appliedAt,
            proposedBudget: proposedBudget
        )
    }
}
