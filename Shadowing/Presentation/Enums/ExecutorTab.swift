import Foundation

enum ExecutorTab: String, CaseIterable {
    case allTasks       = "All Tasks"
    case availableTasks = "Available Tasks"
    case assignedTasks  = "Assigned Tasks"
    case completedTasks = "Completed Tasks"

    var tabName: LocalizedStringResource {
        switch self {
            case .allTasks:       return "All"
            case .availableTasks: return "Available"
            case .assignedTasks:  return "Assigned"
            case .completedTasks: return "Completed"
        }
    }

    var title: LocalizedStringResource {
        switch self {
            case .allTasks:       return "All Tasks"
            case .availableTasks: return "Available Tasks"
            case .assignedTasks:  return "Assigned Tasks"
            case .completedTasks: return "Completed Tasks"
        }
    }
}
