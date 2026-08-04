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
                    async let lookups: () = container.lookupStore.loadIfNeeded()
                    try? await container.authRepository.loadCurrentUser()
                    await lookups

                    if container.authRepository.isAdmin {
                        container.setAppState(.admin)
                    } else if container.authRepository.isAuthenticated {
                        container.setAppState(.main)
                        async let executorRatings: () = container.executorViewModel.checkPendingRatings()
                        async let requesterRatings: () = container.requesterViewModel.checkPendingRatings()
                        _ = await (executorRatings, requesterRatings)
                    }
                }
                .environment(container)
                .preferredColorScheme(container.appearanceManager.currentMode.colorScheme)
        }
    }
}
