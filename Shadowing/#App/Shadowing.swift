import SwiftUI
import FirebaseCore

@main
struct Shadowing: App {
    
    @State private var container = DIContainer()
    @AppStorage("appColorScheme") private var appColorScheme: AppColorScheme = .dark
    
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
                            async let executorRatings: () = container.executorViewModel.checkPendingRatings()
                            async let requesterRatings: () = container.requesterViewModel.checkPendingRatings()
                            _ = await (executorRatings, requesterRatings)
                        }
                    } catch {
                        _ = AuthError.unauthorized
                        container.setAppState(.main)
                    }
                }
                .environment(container)
                .preferredColorScheme(appColorScheme.colorScheme)
        }
    }
}
