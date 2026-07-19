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
    let currency: String
    
    let priority: TaskPriority
    let serviceType: TaskService
    
    let address: String
    let latitude: Double?
    let longitude: Double?
    
    let status: TaskStatus
    let escrowStatus: EscrowStatus
    
    let scheduledAt: Date?
    let preferredTimeOfDay: PreferredTimeOfDay?
    
    let isRatedByRequester: Bool
    let isRatedByExecutor: Bool
    
    let createdAt: Date
    let updatedAt: Date
    
    let requester: UserSummaryDTO
    let executor: UserSummaryDTO?
    
    let applicantsCount: Int
    let isApplicant: Bool
}

extension TaskDTO {
    
    func toDomain() -> TaskModel {
        
        TaskModel(
            id: id,
            title: title,
            description: description,
            budget: budget,
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
            isApplicant: isApplicant
        )
    }
}
