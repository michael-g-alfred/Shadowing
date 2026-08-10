import Foundation

enum NotificationType: String, Codable {
    case taskApplied
    case taskAccepted
    case taskDeclined
    case taskCompleted
    case taskConfirmed
    case taskCancelled
    case taskWithdrawn
    case newMessage
    case ratingReceived
    case system
    
    var iconName: String {
        switch self {
            case .taskApplied: return "person.badge.plus"
            case .taskAccepted: return "checkmark.circle"
            case .taskDeclined: return "hand.raised.slash"
            case .taskCompleted: return "flag.pattern.checkered"
            case .taskConfirmed: return "checkmark.seal"
            case .taskCancelled: return "xmark.circle"
            case .taskWithdrawn: return "arrow.uturn.left.circle"
            case .newMessage: return "message.circle"
            case .ratingReceived: return "star.circle.fill"
            case .system: return "bell.circle"
        }
    }
}

struct NotificationModel: Identifiable, Codable, Equatable {
    let id: String
    let userId: String
    let type: NotificationType
    let title: String
    let body: String
    let taskId: String?
    let isRead: Bool
    let createdAt: Date
    
    init(
        id: String = UUID().uuidString,
        userId: String,
        type: NotificationType,
        title: String,
        body: String,
        taskId: String? = nil,
        isRead: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.type = type
        self.title = title
        self.body = body
        self.taskId = taskId
        self.isRead = isRead
        self.createdAt = createdAt
    }
}
