import Foundation

enum ExecutorTab: String, CaseIterable {
    case availableTasks = "Available Tasks"
    case assignedTasks  = "Assigned Tasks"
    case completedTasks = "Completed Tasks"

    var tabName: LocalizedStringResource {
        switch self {
            case .availableTasks: return "Available"
            case .assignedTasks:  return "Assigned"
            case .completedTasks: return "Completed"
        }
    }

    var title: LocalizedStringResource {
        switch self {
            case .availableTasks: return "Available Tasks"
            case .assignedTasks:  return "Assigned Tasks"
            case .completedTasks: return "Completed Tasks"
        }
    }
    
    var symbolName: String {
        switch self {
            case .availableTasks: return "list.bullet"
            case .assignedTasks: return "person.crop.circle.badge.checkmark"
            case .completedTasks: return "checkmark.seal"
        }
    }
}
