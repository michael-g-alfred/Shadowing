import SwiftUI

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
            case .cancel: return "Cancel Task"
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
    
        /// Same tint used for this action in the list's swipe actions.
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
}
