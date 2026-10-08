import SwiftUI

enum TaskSwipeEdge {
    case leading
    case trailing
}

enum TaskDetailAction: Identifiable {
    case cancel, publish, delete, applicants, pay, refund
    case chats, apply, withdraw, markDone, confirmCompletion
    
    var id: Self { self }
    
    var title: LocalizedStringResource {
        switch self {
            case .cancel: return "Cancel Task"
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
            case .confirmCompletion: return "checkmark.seal.fill"
        }
    }
    
    var color: Color {
        switch self {
            case .cancel: return .orange
            case .publish, .chats: return .blue
            case .delete, .refund, .withdraw: return .red
            case .applicants: return .indigo
            case .pay, .apply, .markDone, .confirmCompletion: return .green
        }
    }
    
    var role: ButtonRole? {
        switch self {
            case .delete, .refund, .withdraw: return .destructive
            case .markDone, .confirmCompletion:
                if #available(iOS 26, *) { return .confirm } else { return nil }
            default: return nil
        }
    }
    
    var swipeEdge: TaskSwipeEdge {
        switch self {
            case .cancel, .delete, .refund, .withdraw: return .trailing
            default: return .leading
        }
    }
    
    var requiresConfirmation: Bool {
        switch self {
            case .cancel, .delete, .refund, .withdraw: return true
            default: return false
        }
    }
    
    var allowsFullSwipe: Bool {
        !requiresConfirmation && role != .destructive
    }
    
    var swipePriority: Int {
        switch self {
            case .pay, .confirmCompletion, .markDone, .apply, .publish: return 0
            case .applicants: return 1
            case .chats: return 2
            case .cancel: return 3
            case .withdraw: return 4
            case .refund: return 5
            case .delete: return 6
        }
    }
    
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
        if task.status == TaskStatus.published.rawValue
            || task.status == TaskStatus.pending.rawValue
            || task.status == TaskStatus.pendingPayment.rawValue {
            actions.append(.cancel)
        }
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
            actions.append(task.isApplicant ? .withdraw : .apply)
        }
        if task.status == TaskStatus.inProgress.rawValue {
            actions.append(.markDone)
            actions.append(.chats)
            actions.append(.withdraw)
        }
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
    func swipe(_ edge: TaskSwipeEdge, limit: Int = 2) -> [TaskDetailAction] {
        filter { $0.swipeEdge == edge }
            .sorted { $0.swipePriority < $1.swipePriority }
            .prefix(limit)
            .map { $0 }
    }
    
    var menuOnly: [TaskDetailAction] {
        let inSwipe = Set(swipe(.leading) + swipe(.trailing))
        return filter { !inSwipe.contains($0) }
            .sorted { $0.swipePriority < $1.swipePriority }
    }
}
