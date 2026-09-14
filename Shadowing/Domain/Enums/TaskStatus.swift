import Foundation

enum TaskStatus: String {
    case published
    case pending
    case pendingPayment = "pending_payment"
    case inProgress = "in_progress"
    case pendingCompleted = "pending_completed"
    case completed
    case cancelled
}
