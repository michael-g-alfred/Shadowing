import SwiftUI
import FirebaseCore

@main
struct Shadowing: App {
    
    @State private var container = DIContainer()
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            container.makeRootView()
                .task {
                    do {
                        try await container.authRepository.loadCurrentUser()
                        if container.authRepository.isAdmin {
                            container.setAppState(.admin)
                        } else if container.authRepository.isAuthenticated {
                            container.setAppState(.main)
                        }
                    } catch {
                        _ = AuthError.unauthorized
                        container.setAppState(.main)
                    }
                }
                .environment(container)
        }
    }
}
