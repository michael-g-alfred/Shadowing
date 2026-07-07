import SwiftUI

struct RootView: View {
    
    @Environment(DIContainer.self) private var container
    
    var body: some View {
        Group {
            switch container.appState {
                case .onboarding:
                    container.makeOnboardingView()
                    
                case .auth:
                    AuthCoordinatorView()
                    
                case .main:
                    container.makeMainView()
                        .onAppear {
                            CLLocationServiceImpl().requestLocation()
                        }
                    
                case .admin:
                    container.makeAdminDashboardView()
            }
        }
        .id(container.rootID)
        .animation(.easeInOut, value: container.appState)
    }
}
