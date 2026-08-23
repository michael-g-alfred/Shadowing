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
    case taskInvitation
    case system
    
    var iconName: String {
        switch self {
            case .taskApplied: return "plus.circle"
            case .taskAccepted: return "checkmark.circle"
            case .taskDeclined: return "slash.circle"
            case .taskCompleted: return "flag.circle"
            case .taskConfirmed: return "checkmark.seal"
            case .taskCancelled: return "xmark.circle"
            case .taskWithdrawn: return "arrow.uturn.left.circle"
            case .newMessage: return "bubble.circle"
            case .ratingReceived: return "star.circle"
            case .taskInvitation: return "envelope.circle"
            case .system: return "bell.circle"
        }
    }
    
    var title: LocalizedStringResource {
        switch self {
            case .taskApplied: return "New Applicant"
            case .taskAccepted: return "Application Accepted"
            case .taskDeclined: return "Application Declined"
            case .taskCompleted: return "Task Completed"
            case .taskConfirmed: return "Completion Confirmed"
            case .taskCancelled: return "Task Cancelled"
            case .taskWithdrawn: return "Executor Withdrew"
            case .newMessage: return "New Message"
            case .ratingReceived: return "New Rating"
            case .taskInvitation: return "Task Invitation"
            case .system: return "Notification"
        }
    }
    
}

struct NotificationModel: Identifiable, Codable, Equatable {
    let id: String
    let userId: String
    let type: NotificationType
    let subjectText: String?
    let messageText: String?
    
    let taskId: String?
    let isRead: Bool
    let createdAt: Date
    
    init(
        id: String = UUID().uuidString,
        userId: String,
        type: NotificationType,
        subjectText: String? = nil,
        messageText: String? = nil,
        taskId: String? = nil,
        isRead: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.type = type
        self.subjectText = subjectText
        self.messageText = messageText
        self.taskId = taskId
        self.isRead = isRead
        self.createdAt = createdAt
    }
    
        /// The bold header line. For `.newMessage` it's the sender's name
        /// (carried in `subjectText`); for every other type it's the fixed
        /// localized category label (e.g. "New Applicant").
    var title: LocalizedStringResource {
        if type == .newMessage {
            return LocalizedStringResource(stringLiteral: subjectText ?? String(localized: type.title))
        }
        return type.title
    }

        /// The detail line — the full sentence composed by the sender and
        /// stored in `messageText` (e.g. `Michael applied to your task "…"`).
    var body: LocalizedStringResource {
        LocalizedStringResource(stringLiteral: messageText ?? "")
    }
}
