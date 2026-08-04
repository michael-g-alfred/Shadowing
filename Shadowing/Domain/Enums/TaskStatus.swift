import Foundation

enum TaskStatus: String {
    case published
    case pending
    case inProgress = "in_progress"
    case pendingCompleted = "pending_completed"
    case completed
    case cancelled
}
