import SwiftUI

enum TaskSwipeEdge {
    case leading
    case trailing
}

enum TaskDetailAction: Identifiable {
    case applicants
    case confirmCompletion
    case chats
    case delete
    case cancel
    case publish
    case accept
    case withdraw
    case markDone
    
    var id: Self { self }
    
    var title: LocalizedStringResource {
        switch self {
            case .applicants: return "Applicants"
            case .confirmCompletion: return "Confirm Completion"
            case .chats: return "Chats"
            case .delete: return "Delete"
            case .cancel: return "Cancel"
            case .publish: return "Publish"
            case .accept: return "Accept"
            case .withdraw: return "Withdraw"
            case .markDone: return "Mark as Done"
        }
    }
    
    var systemImage: String {
        switch self {
            case .applicants: return "person.3.fill"
            case .confirmCompletion: return "checkmark.seal"
            case .chats: return "bubble.left.and.bubble.right.fill"
            case .delete: return "trash"
            case .cancel: return "xmark.circle"
            case .publish: return "square.and.arrow.up.badge.checkmark"
            case .accept: return "checkmark.circle"
            case .withdraw: return "arrow.uturn.backward"
            case .markDone: return "checkmark.seal"
        }
    }
    
    var color: Color {
        switch self {
            case .applicants: return .orange
            case .confirmCompletion: return .green
            case .chats: return .blue
            case .delete: return .red
            case .cancel: return .yellow
            case .publish: return .blue
            case .accept: return .green
            case .withdraw: return .red
            case .markDone: return .green
        }
    }
    
    var role: ButtonRole? {
        switch self {
            case .delete, .withdraw: return .destructive
            case .markDone: return .confirm
            default: return nil
        }
    }
    
    var swipeEdge: TaskSwipeEdge {
        switch self {
            case .applicants, .confirmCompletion, .chats, .markDone:
                return .leading
            case .delete, .cancel, .publish, .accept, .withdraw:
                return .trailing
        }
    }
    
        // MARK: - Availability by role & status
    
    static func requesterActions(for task: TaskModel) -> [TaskDetailAction] {
        var actions: [TaskDetailAction] = []
        
        if task.status == TaskStatus.published.rawValue || task.status == TaskStatus.pending.rawValue {
            actions.append(.applicants)
        }
        if task.status == TaskStatus.pendingCompleted.rawValue {
            actions.append(.confirmCompletion)
        }
        if task.status == TaskStatus.inProgress.rawValue || task.status == TaskStatus.pendingCompleted.rawValue {
            actions.append(.chats)
        }
        if task.status == TaskStatus.published.rawValue || task.status == TaskStatus.pending.rawValue {
            actions.append(.cancel)
        }
        if task.status == TaskStatus.cancelled.rawValue {
            actions.append(.publish)
        }
        if task.status == TaskStatus.published.rawValue
            || task.status == TaskStatus.pending.rawValue
            || task.status == TaskStatus.cancelled.rawValue {
            actions.append(.delete)
        }
        return actions
    }


    static func executorActions(for task: TaskModel) -> [TaskDetailAction] {
        var actions: [TaskDetailAction] = []
        
        if task.status == TaskStatus.published.rawValue || task.status == TaskStatus.pending.rawValue {
            if task.isApplicant {
                actions.append(.withdraw)
            } else {
                actions.append(.accept)
            }
        }
        if task.status == TaskStatus.inProgress.rawValue {
            actions.append(.markDone)
            actions.append(.chats)
            actions.append(.withdraw)
        }
        if task.status == TaskStatus.pendingCompleted.rawValue {
            actions.append(.chats)
        }
        return actions
    }
}

extension Array where Element == TaskDetailAction {
        /// Actions from this list that render as leading swipe actions.
    var leading: [TaskDetailAction] { filter { $0.swipeEdge == .leading } }
        /// Actions from this list that render as trailing swipe actions.
    var trailing: [TaskDetailAction] { filter { $0.swipeEdge == .trailing } }
}
