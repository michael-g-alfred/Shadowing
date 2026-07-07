import Foundation

enum RequesterTab: String, CaseIterable {
    case publishedTasks = "Published Tasks"
    case completedTasks = "Completed Tasks"

    var tabName: LocalizedStringResource {
        switch self {
            case .publishedTasks: return "Published"
            case .completedTasks: return "Completed"
        }
    }

    var title: LocalizedStringResource {
        switch self {
            case .publishedTasks: return "Published Tasks"
            case .completedTasks: return "Completed Tasks"
        }
    }
}
