import SwiftUI

enum EmptyState: CaseIterable {
    case noTasks
    case noRequesterPublishedTasks
    case noRequesterCompletedTasks
    case noAvailableTasks
    case noAssignedTasks
    case noExecutorCompletedTasks
    case noExecutorFavoriteTasks
    case noFilteredRequesterTasks
    case noChats
    case noApplicantsYet
    case noNotifications
    case noProfile
    case noTaskSelection
    case noLocationAccess
    
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
            case .noFilteredRequesterTasks:
                return "No Matching Tasks"
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
            case .noLocationAccess:
                return "Location Access Needed"
        }
    }
    
    var description: LocalizedStringResource {
        switch self {
            case .noTasks:
                return "No tasks available. Try\nsearching for something else."
            case .noRequesterPublishedTasks:
                return "Post your first task and let someone take care of it for you."
            case .noAvailableTasks:
                return "Check back soon — new tasks are posted all the time."
            case .noAssignedTasks:
                return "Tasks you've been assigned will appear here."
            case .noExecutorCompletedTasks, .noRequesterCompletedTasks:
                return "Your completed tasks will appear here."
            case .noExecutorFavoriteTasks:
                return "Your favorite tasks will appear here."
            case .noFilteredRequesterTasks:
                return "No tasks match this filter. Try a different status."
            case .noChats:
                return "Active conversations will appear here."
            case .noApplicantsYet:
                return "No one has applied for this task yet."
            case .noNotifications:
                return "You have no notifications yet."
            case .noProfile:
                return "You have no profile yet."
            case .noTaskSelection:
                return "Select a task from the list to view its details."
            case .noLocationAccess:
                return "Please enable location access from Settings to post or browse tasks."
        }
    }
    
    var systemImage: String {
        switch self {
            case .noExecutorCompletedTasks, .noRequesterCompletedTasks:
                return "checklist.unchecked"
            case .noExecutorFavoriteTasks:
                return "star.slash"
            case .noFilteredRequesterTasks:
                return "line.3.horizontal.decrease.circle"
            case .noChats:
                return "bubble.left.and.text.bubble.right"
            case .noApplicantsYet:
                return "person.slash"
            case .noNotifications:
                return "bell.slash"
            case .noProfile:
                return "person.crop.circle"
            case .noLocationAccess:
                return "location.slash"
            default:
                return "tray"
        }
    }
    
    @ViewBuilder
    func view(
        retryAction: (() async -> Void)? = nil,
        clearFilterAction: (() -> Void)? = nil,
        settingsAction: (() -> Void)? = nil
    ) -> some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
        } description: {
            Text(description)
                .frame(width: 250)
                .multilineTextAlignment(.center)
        } actions: {
            if self == .noLocationAccess, let settingsAction {
                Button("Open Settings") {
                    settingsAction()
                }
                .controlSize(.regular)
                .buttonStyle(.glassProminent)
            } else if self == .noFilteredRequesterTasks || self == .noExecutorFavoriteTasks, let clearFilterAction {
                Button(self == .noExecutorFavoriteTasks ? "Remove Favorites Filter" : "Remove Filter") {
                    clearFilterAction()
                }
                .controlSize(.regular)
                .buttonStyle(.glassProminent)
            } else if let retryAction {
                Button("Try Again") {
                    Task { await retryAction() }
                }
                .controlSize(.regular)
                .buttonStyle(.glassProminent)
            }
        }
    }
}
