import SwiftUI

    // MARK: - Pending Rating

    /// A unified representation of a rating that is currently pending presentation.
    ///
    /// The app supports two independent rating flows:
    /// - Executor rates the requester.
    /// - Requester rates the executor.
    ///
    /// `PendingRating` normalizes both flows into one value so `RootView`
    /// can drive a single sheet presentation.
private struct PendingRating: Identifiable {
    
        // MARK: Source
    
    enum Source {
            /// The signed-in user is the executor and needs to rate the requester.
        case executor
        
            /// The signed-in user is the requester and needs to rate the executor.
        case requester
    }
    
        // MARK: Properties
    
        /// The task associated with this pending rating.
    let task: TaskModel
    
        /// The user being rated.
    let target: RatingTarget
    
        /// Which rating flow produced this pending rating.
    let source: Source
    
        /// A unique identifier for the pending rating.
        ///
        /// Including the source prevents two different rating flows
        /// for the same task from being treated as the same Identifiable item.
    var id: String {
        switch source {
            case .executor:
                "\(task.id)-executor"
                
            case .requester:
                "\(task.id)-requester"
        }
    }
}

    // MARK: - Root View

    /// The top-level view of the application.
    ///
    /// `RootView` is responsible for:
    /// - Routing between major application states.
    /// - Presenting global sheets that belong to the main application flow.
    /// - Reading shared dependencies and ViewModels from `DIContainer`.
    ///
    /// `DIContainer` is the single source of truth for the app's shared ViewModels.
struct RootView: View {
    
        // MARK: Environment
    
    @Environment(DIContainer.self) private var container
    
        // MARK: Pending Rating
    
        /// The rating currently waiting to be presented.
        ///
        /// The executor flow is checked first, followed by the requester flow.
        /// If neither flow has a pending rating, this returns `nil`.
    private var pendingRating: PendingRating? {
        
            // Executor → Rate Requester
        if let task = container.executorViewModel.currentRatingTask {
            
            return PendingRating(
                task: task,
                target: .requester(
                    userId: task.requester.id,
                    displayName: task.requester.displayName
                ),
                source: .executor
            )
        }
        
            // Requester → Rate Executor
        if let task = container.requesterViewModel.currentRatingTask,
           let executor = task.executor {
            
            return PendingRating(
                task: task,
                target: .executor(
                    userId: executor.id,
                    displayName: executor.displayName
                ),
                source: .requester
            )
        }
        
        return nil
    }
    
        // MARK: Body
    
    var body: some View {
        Group {
            switch container.appState {
                    
                        // MARK: Setup
                    
                case .setup:
                    container.makeSetupFlowView()
                    
                        // MARK: Onboarding
                    
                case .onboarding:
                    container.makeOnboardingView()
                    
                        // MARK: Authentication
                    
                case .auth:
                    AuthCoordinatorView()
                    
                        // MARK: Main
                    
                case .main:
                    mainContent
                    
                        // MARK: Admin
                    
                case .admin:
                    container.makeAdminDashboardView()
            }
        }
        .animation(
            .spring(
                response: 0.35,
                dampingFraction: 0.75
            ),
            value: container.appState
        )
        .responseAlert(
            isPresented: Bindable(AlertCenter.shared).isPresented,
            type: AlertCenter.shared.type,
            message: AlertCenter.shared.message
        )
    }
    
        // MARK: Main Content
    
        /// Main application content and all global sheets/alerts
        /// associated with the requester and executor flows.
    @ViewBuilder
    private var mainContent: some View {
        
        container.makeMainView()
            .requireLocation(container.locationService)
        
            // MARK: Rating Sheet
        
            .sheet(
                item: Binding(
                    get: {
                        pendingRating
                    },
                    set: { newValue in
                        handleRatingSheetChange(newValue)
                    }
                )
            ) { pending in
                
                container.makeRatingSheet(
                    taskId: pending.task.id,
                    taskTitle: pending.task.title,
                    target: pending.target
                )
                .appSheetStyle(
                    interactiveDismissDisabled: true
                )
            }
        
            // MARK: Executor - Applied Sheet
        
            .sheet(
                isPresented: Binding(
                    get: {
                        container.executorViewModel.showAppliedSheet
                    },
                    set: {
                        container.executorViewModel.showAppliedSheet = $0
                    }
                )
            ) {
                AppliedSheet(
                    vm: container.executorViewModel
                )
                .appSheetStyle()
            }
        
            // MARK: Executor - Direct Chat
        
            .sheet(
                isPresented: Binding(
                    get: {
                        container.executorViewModel.selectedChatTaskId != nil
                    },
                    set: { isPresented in
                        if !isPresented {
                            container.executorViewModel.selectedChatTaskId = nil
                        }
                    }
                )
            ) {
                if let taskId = container.executorViewModel.selectedChatTaskId {
                    container.makeDirectChatDetailView(
                        taskId: taskId
                    )
                    .appSheetStyle()
                }
            }
        
            // MARK: Executor - Apply Confirmation
        
            .alert(
                "Confirm Task Application",
                isPresented: Binding(
                    get: {
                        container.executorViewModel.showFeeConfirmationAlert
                    },
                    set: {
                        container.executorViewModel.showFeeConfirmationAlert = $0
                    }
                )
            ) {
                
                Button("Cancel", role: .cancel) {
                    container.executorViewModel.cancelApply()
                }
                
                Button("Confirm", role: .confirm) {
                    Task {
                        await container.executorViewModel.confirmApply()
                    }
                }
                
            } message: {
                Text(
                    container.executorViewModel.feeConfirmationMessage
                )
            }
        
            // MARK: Requester - Add Task
        
            .sheet(
                isPresented: Binding(
                    get: {
                        container.requesterViewModel.showAddTaskSheet
                    },
                    set: {
                        container.requesterViewModel.showAddTaskSheet = $0
                    }
                )
            ) {
                container.makeAddTaskSheet()
                    .appSheetStyle(
                        interactiveDismissDisabled: true
                    )
            }
        
            // MARK: Requester - Applicants
        
            .sheet(
                isPresented: Binding(
                    get: {
                        container.requesterViewModel.showApplicantsSheet
                    },
                    set: {
                        container.requesterViewModel.showApplicantsSheet = $0
                    }
                )
            ) {
                container.makeApplicantsSheet()
                    .appSheetStyle()
            }
        
            // MARK: Requester - Direct Chat
        
            .sheet(
                isPresented: Binding(
                    get: {
                        container.requesterViewModel.selectedChatTaskId != nil
                    },
                    set: { isPresented in
                        if !isPresented {
                            container.requesterViewModel.selectedChatTaskId = nil
                        }
                    }
                )
            ) {
                if let taskId = container.requesterViewModel.selectedChatTaskId {
                    container.makeDirectChatDetailView(
                        taskId: taskId
                    )
                    .appSheetStyle()
                }
            }
    }
    
        // MARK: Rating Sheet Handling
    
        /// Handles changes to the rating sheet binding.
        ///
        /// A `nil` value can be produced when the sheet is dismissed.
        /// The actual submission state should be managed by the corresponding
        /// ViewModel rather than assuming every dismissal means a successful rating.
    private func handleRatingSheetChange(
        _ newValue: PendingRating?
    ) {
        
        guard newValue == nil else {
            return
        }
        
        guard let current = pendingRating else {
            return
        }
        
        switch current.source {
                
            case .executor:
                container.executorViewModel.ratingSheetDismissed(
                    for: current.task.id,
                    wasSubmitted: true
                )
                
            case .requester:
                container.requesterViewModel.ratingSheetDismissed(
                    for: current.task.id,
                    wasSubmitted: true
                )
        }
    }
}
