import Foundation

enum RequesterStatusFilter: LocalizedStringResource, CaseIterable, Identifiable {
    case all
    case published
    case pending
    case pendingPayment
    case inProgress
    case pendingCompleted

    var id: String { "requester-status-filter.\(self.rawValue)" }

    var title: LocalizedStringResource {
        switch self {
            case .all: return "All"
            case .published: return "Published"
            case .pending: return "Pending"
            case .pendingPayment: return "Pending Payment"
            case .inProgress: return "In progress"
            case .pendingCompleted: return "Pending completed"
        }
    }

    var apiValue: String? {
        switch self {
            case .all: return nil
            case .published: return "published"
            case .pending: return "pending"
            case .pendingPayment: return "pending_payment"
            case .inProgress: return "in_progress"
            case .pendingCompleted: return "pending_completed"
        }
    }
}
