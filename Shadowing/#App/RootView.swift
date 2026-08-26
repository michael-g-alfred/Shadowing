import SwiftUI

    // MARK: - Root View

    /// The top-level view of the application.
    ///
    /// `RootView` is responsible for routing between major application states
    /// and reading shared dependencies from `DIContainer`.
struct RootView: View {
    
        // MARK: Environment
    
    @Environment(DIContainer.self) private var container
    
        // MARK: Body
    
    var body: some View {
        Group {
            switch container.appState {
                case .setup: container.makeSetupFlowView()           // MARK: Setup
                case .onboarding: container.makeOnboardingView()     // MARK: Onboarding
                case .auth: AuthCoordinatorView()                    // MARK: Authentication
                case .main: mainContent                              // MARK: Main
                case .admin: container.makeAdminDashboardView()      // MARK: Admin
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: container.appState)
        .responseAlert(
            isPresented: Bindable(AlertCenter.shared).isPresented,
            type: AlertCenter.shared.type,
            message: AlertCenter.shared.message
        )
    }
    
        // MARK: Main Content
    
        /// Main application content with attached global sheets and location requirements.
    @ViewBuilder
    private var mainContent: some View {
        container.makeMainView()
            .requireLocation(container.locationService)
            .withGlobalSheets()
    }
}
