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
                        container.chatViewModel.listenToConversations()
                        container.notificationViewModel.startListening()
                        async let notification = container.notificationService.requestAuthorization()
                        async let executorRatings: () = container.executorViewModel.checkPendingRatings()
                        async let requesterRatings: () = container.requesterViewModel.checkPendingRatings()
                        _ = await (notification, executorRatings, requesterRatings)
                    }
                }
                .task(id: container.languageManager.currentLanguage) {
                    await container.lookupStore.loadIfNeeded()
                }
                .environment(\.layoutDirection, container.languageManager.currentLanguage.layoutDirection)
                .environment(\.locale, container.languageManager.currentLanguage.locale)
                .id(container.rootID)
                .id(container.languageManager.currentLanguage)
                .environment(container)
                .preferredColorScheme(container.appearanceManager.currentMode.colorScheme)
        }
    }
}
