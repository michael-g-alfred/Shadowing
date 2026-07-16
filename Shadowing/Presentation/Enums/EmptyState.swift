import SwiftUI

enum EmptyState: CaseIterable {
    case noTasks
    case noRequesterPublishedTasks
    case noRequesterCompletedTasks
    case noAvailableTasks
    case noAssignedTasks
    case noExecutorCompletedTasks
    case noExecutorFavoriteTasks
    case noChats
    case noApplicantsYet
    case noNotifications
    case noProfile
    case noTaskSelection
    
    var title: LocalizedStringResource {
        switch self {
            case .noTasks:
                return "No Tasks"
            case .noAvailableTasks, .noRequesterPublishedTasks:
                return "No Tasks Available"
            case .noAssignedTasks:
                return "No Assigned Tasks"
            case .noExecutorCompletedTasks, .noRequesterCompletedTasks:
                return "No Completed Tasks"
            case .noExecutorFavoriteTasks:
                return "No Favorite Tasks"
            case .noChats:
                return "No Chats Available"
            case .noApplicantsYet:
                return "No Applicants Yet"
            case .noNotifications:
                return "No Notifications"
            case .noProfile:
                return "No Profile"
            case .noTaskSelection:
                return "No Task Selection"
        }
    }
    
    var description: LocalizedStringResource {
        switch self {
            case .noTasks:
                return "No tasks available. Try\nsearching for something else."
            case .noRequesterPublishedTasks:
                return "Post your first task and let\nsomeone take care of it for you."
            case .noAvailableTasks:
                return "Check back soon — new tasks\nare posted all the time."
            case .noAssignedTasks:
                return "Tasks you've been assigned will appear here."
            case .noExecutorCompletedTasks, .noRequesterCompletedTasks:
                return "Your completed tasks will appear here."
            case .noExecutorFavoriteTasks:
                return "Your favorite tasks will appear here."
            case .noChats:
                return "Active conversations will appear here."
            case .noApplicantsYet:
                return "No one has accepted this task yet."
            case .noNotifications:
                return "You have no notifications yet."
            case .noProfile:
                return "You have no profile yet."
            case .noTaskSelection:
                return "Select a task from the list to view its details."
        }
    }
    
    var systemImage: String {
        switch self {
            case .noExecutorCompletedTasks, .noRequesterCompletedTasks:
                return "checklist.unchecked"
            case .noExecutorFavoriteTasks:
                return "star.slash"
            case .noChats:
                return "bubble.left.and.text.bubble.right"
            case .noApplicantsYet:
                return "person.slash"
            case .noNotifications:
                return "bell.badge"
            case .noProfile:
                return "person.crop.circle"
            default:
                return "tray"
        }
    }
    
    @ViewBuilder
    func view(retryAction: (() async -> Void)? = nil) -> some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
        } description: {
            Text(description)
        } actions: {
            if let retryAction {
                Button("Try Again") {
                    Task { await retryAction() }
                }
                .controlSize(.regular)
                .buttonStyle(.glassProminent)
            }
        }
    }
}
