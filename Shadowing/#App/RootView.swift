import SwiftUI

    // MARK: - Root View

    /// The top-level view of the application.
    ///
    /// `RootView` is responsible for:
    /// - Routing between major application states.
    /// - Reading shared dependencies and ViewModels from `DIContainer`.
    ///
    /// Global sheets/alerts for the main flow are attached via
    /// `.withGlobalSheets()`, defined in `GlobalSheetsModifier.swift`.
struct RootView: View {
    
        // MARK: Environment
    
    @Environment(DIContainer.self) private var container
    
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
    
        /// Main application content. All global sheets/alerts for the
        /// requester and executor flows are attached via `.withGlobalSheets()`.
    @ViewBuilder
    private var mainContent: some View {
        
        container.makeMainView()
            .requireLocation(container.locationService)
            .withGlobalSheets()
    }
}
