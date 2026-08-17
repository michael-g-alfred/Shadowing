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
    let originalBudget: Double?
    let currency: String
    let priority: String
    let serviceType: String
    let address: String
    let latitude: Double?
    let longitude: Double?
    var status: String
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
    var isApplicant: Bool
    var isFavourite: Bool
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude ?? 31.2565, longitude: longitude ?? 32.2841)
    }
    
        /// Whether the accepted budget differs from the task's original budget
        /// (i.e. an applicant's proposed budget was accepted on assignment).
    var budgetDidChange: Bool {
        guard let originalBudget else { return false }
        return originalBudget != budget
    }
    
        /// True if the accepted budget is higher than the original, false if lower.
        /// Only meaningful when `budgetDidChange` is true.
    var budgetIncreased: Bool {
        (originalBudget ?? budget) < budget
    }
}
