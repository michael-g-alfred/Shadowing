import SwiftUI

private struct PendingRating: Identifiable {
    enum Source {
        case executor   // this task needs the EXECUTOR to rate the requester
        case requester  // this task needs the REQUESTER to rate the executor
    }
    
    let task: TaskModel
    let target: RatingTarget
    let source: Source
    
    var id: String { task.id }
}

struct RootView: View {
    
    @Environment(DIContainer.self) private var container
    
    private var pendingRating: PendingRating? {
        if let task = container.executorViewModel.currentRatingTask {
            return PendingRating(
                task: task,
                target: .requester(displayName: task.requester.displayName),
                source: .executor
            )
        }
        if let task = container.requesterViewModel.currentRatingTask {
            return PendingRating(
                task: task,
                target: .executor(displayName: task.executor?.displayName ?? ""),
                source: .requester
            )
        }
        return nil
    }
    
    var body: some View {
        Group {
            switch container.appState {
                case .onboarding:
                    container.makeOnboardingView()
                    
                case .setup:
                    container.makeSetupFlowView()
                    
                case .auth:
                    AuthCoordinatorView()
                    
                case .main:
                    container.makeMainView()
                        .task {
                            CLLocationServiceImpl().requestLocation()
                            container.chatViewModel.listenToConversations()
                        }
                        .sheet(item: Binding(
                            get: { pendingRating },
                            set: { newValue in
                                guard newValue == nil, let current = pendingRating else { return }
                                switch current.source {
                                    case .executor:
                                        container.executorViewModel.ratingSheetDismissed(
                                            for: current.task.id, wasSubmitted: true
                                        )
                                    case .requester:
                                        container.requesterViewModel.ratingSheetDismissed(
                                            for: current.task.id, wasSubmitted: true
                                        )
                                }
                            }
                        )) { pending in
                            container.makeRatingSheet(
                                taskId: pending.task.id,
                                taskTitle: pending.task.title,
                                target: pending.target
                            )
                            .appSheetStyle(interactiveDismissDisabled: true)
                        }
                    
                case .admin:
                    container.makeAdminDashboardView()
            }
        }
        .environment(\.layoutDirection, container.languageManager.currentLanguage.layoutDirection)
        .environment(\.locale, container.languageManager.currentLanguage.locale)
        .id(container.rootID)
        .id(container.languageManager.currentLanguage)
        .animation(.easeInOut, value: container.appState)
        .responseAlert(
            isPresented: Bindable(AlertCenter.shared).isPresented,
            type: AlertCenter.shared.type,
            message: AlertCenter.shared.message
        )
    }
}
