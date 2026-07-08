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
        .environment(\.layoutDirection, container.languageManager.currentLanguage == .arabic ? .rightToLeft : .leftToRight)
        .environment(\.locale, Locale(identifier: container.languageManager.currentLanguage.rawValue))
        .id(container.rootID)
        .animation(.easeInOut, value: container.appState)
    }
}
