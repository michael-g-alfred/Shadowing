import SwiftUI

enum TaskSwipeEdge {
    case leading
    case trailing
}

enum TaskDetailAction: Identifiable {
    case cancel
    case publish
    case delete
    case applicants
    case pay
    case refund
    case chats
    case apply
    case withdraw
    case markDone
    case confirmCompletion
    
    var id: Self { self }
    
    var title: LocalizedStringResource {
        switch self {
            case .cancel: return "Cancel"
            case .publish: return "Publish"
            case .delete: return "Delete"
            case .applicants: return "Applicants"
            case .pay: return "Pay Now"
            case .refund: return "Refund"
            case .chats: return "Chats"
            case .apply: return "Apply"
            case .withdraw: return "Withdraw"
            case .markDone: return "Mark as Done"
            case .confirmCompletion: return "Confirm Completion"
        }
    }
    
    var systemImage: String {
        switch self {
            case .cancel: return "xmark.circle"
            case .publish: return "square.and.arrow.up.badge.checkmark"
            case .delete: return "trash"
            case .applicants: return "person.3.fill"
            case .pay: return "creditcard.fill"
            case .refund: return "arrow.uturn.backward.circle.fill"
            case .chats: return "bubble.left.and.bubble.right.fill"
            case .apply: return "checkmark.circle"
            case .withdraw: return "arrow.uturn.backward"
            case .markDone: return "checkmark.seal"
            case .confirmCompletion: return "checkmark.seal"
        }
    }
    
    var color: Color {
        switch self {
            case .cancel: return .yellow
            case .publish: return .blue
            case .delete: return .red
            case .applicants: return .orange
            case .pay: return .green
            case .refund: return .red
            case .chats: return .blue
            case .apply: return .green
            case .withdraw: return .red
            case .markDone: return .green
            case .confirmCompletion: return .green
        }
    }
    
    var role: ButtonRole? {
        switch self {
            case .cancel: return .cancel
            case .publish: return nil
            case .delete: return .destructive
            case .applicants: return nil
            case .pay: return nil
            case .refund: return .destructive
            case .chats: return nil
            case .apply: return nil
            case .withdraw: return .destructive
            case .markDone: return .confirm
            case .confirmCompletion: return .confirm
        }
    }
    
    var swipeEdge: TaskSwipeEdge {
        switch self {
            case .cancel: return .trailing
            case .publish: return .leading
            case .delete: return .trailing
            case .applicants: return .leading
            case .pay: return .leading
            case .refund: return .trailing
            case .chats: return .leading
            case .apply: return .leading
            case .withdraw: return .trailing
            case .markDone: return .leading
            case .confirmCompletion: return .leading
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
        if task.status == TaskStatus.pendingPayment.rawValue && task.escrowStatus == EscrowStatus.notPaid.rawValue {
            actions.append(.pay)
            actions.append(.chats)
        }
        // Cancel is also allowed while waiting for payment (nothing was paid yet).
        if task.status == TaskStatus.published.rawValue
            || task.status == TaskStatus.pending.rawValue
            || task.status == TaskStatus.pendingPayment.rawValue {
            actions.append(.cancel)
        }
        // Paid but not finished: the requester can still get the money back
        // while it is held (this also cancels the task).
        if task.status == TaskStatus.inProgress.rawValue
            && task.escrowStatus == EscrowStatus.held.rawValue {
            actions.append(.refund)
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
                actions.append(.apply)
            }
        }
        if task.status == TaskStatus.inProgress.rawValue {
            actions.append(.markDone)
            actions.append(.chats)
            actions.append(.withdraw)
        }
        // Assigned, but the requester hasn't paid yet: the executor may leave
        // freely (the server never counts this as a withdrawal strike).
        if task.status == TaskStatus.pendingPayment.rawValue {
            actions.append(.withdraw)
            actions.append(.chats)
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
