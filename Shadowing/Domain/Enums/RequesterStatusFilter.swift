import Foundation

enum RequesterStatusFilter: LocalizedStringResource, CaseIterable, Identifiable {
    case all
    case published
    case pending
    case inProgress
    case pendingCompleted
    case pendingWithdraw

    var id: String { "requester-status-filter.\(self.rawValue)" }

    var title: LocalizedStringResource {
        switch self {
                
            case .all: return "All"
            case .published: return "Published"
            case .pending: return "Pending"
            case .inProgress: return "In progress"
            case .pendingCompleted: return "Pending completed"
            case .pendingWithdraw: return "Pending withdraw"
                
        }
    }

    var apiValue: String? {
        switch self {
                
            case .all: return nil
            case .published: return "published"
            case .pending: return "pending"
            case .inProgress: return "in_progress"
            case .pendingCompleted: return "pending_completed"
            case .pendingWithdraw: return "pending_withdraw"
                
        }
    }
}
