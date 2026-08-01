import Foundation
import CoreLocation

struct PaginatedTasksResult {
    let tasks: [TaskModel]
    let hasMore: Bool
    let cursor: String?
}

struct TaskModel: Identifiable {
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
    let requester: UserSummaryModel
    let executor: UserSummaryModel?
    let applicantsCount: Int
    let isApplicant: Bool
    var isFavourite: Bool
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude ?? 31.2565, longitude: longitude ?? 32.2841)
    }
    
}
