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
    let priority: String
    let serviceType: String
    let address: String
    let latitude: Double?
    let longitude: Double?
    let status: String
    let escrowStatus: String
    let scheduledAt: Date?
    let preferredTimeOfDay: String?
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
