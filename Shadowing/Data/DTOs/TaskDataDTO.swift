import Foundation

struct TaskListResponseDTO: Codable {
    let tasks: [TaskDTO]
    let hasMore: Bool
    let cursor: String?
}

struct TaskDTO: Codable {
    
    let id: String
    let title: String
    let description: String
    let budget: Double
    let originalBudget: Double?
    let currency: String
    
        // These arrive as plain name strings from the backend (JOIN ... AS name),
        // e.g. priority = "urgent", status = "in_progress", serviceType = "plumbing".
        // Resolve to label/color/icon via LookupStore, never decode into an enum here.
    let priority: String
    let serviceType: String
    let status: String
    let escrowStatus: String
    let preferredTimeOfDay: String?
    
    let address: String
    let latitude: Double?
    let longitude: Double?
    
    let scheduledAt: Date?
    
    let isRatedByRequester: Bool
    let isRatedByExecutor: Bool
    
    let createdAt: Date
    let updatedAt: Date
    
    let requester: UserSummaryDTO
    let executor: UserSummaryDTO?
    
    let applicantsCount: Int
    let isApplicant: Bool
    let isFavorite: Bool

    private enum CodingKeys: String, CodingKey {
        case id, title, description, budget, originalBudget, currency
        case priority, serviceType, status, escrowStatus, preferredTimeOfDay
        case address, latitude, longitude
        case scheduledAt
        case isRatedByRequester, isRatedByExecutor
        case createdAt, updatedAt
        case requester, executor
        case applicantsCount, isApplicant
        case isFavorite
    }
}

extension TaskDTO {
    
    func toDomain() -> TaskModel {
        TaskModel(
            id: id,
            title: title,
            description: description,
            budget: budget,
            originalBudget: originalBudget,
            currency: currency,
            priority: priority,
            serviceType: serviceType,
            address: address,
            latitude: latitude,
            longitude: longitude,
            status: status,
            escrowStatus: escrowStatus,
            scheduledAt: scheduledAt,
            preferredTimeOfDay: preferredTimeOfDay,
            isRatedByRequester: isRatedByRequester,
            isRatedByExecutor: isRatedByExecutor,
            createdAt: createdAt,
            updatedAt: updatedAt,
            requester: requester.toDomain(),
            executor: executor?.toDomain(),
            applicantsCount: applicantsCount,
            isApplicant: isApplicant,
            isFavorite: isFavorite
        )
    }
}
