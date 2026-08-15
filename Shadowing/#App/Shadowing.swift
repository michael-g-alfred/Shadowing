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
                    try? await container.authRepository.loadCurrentUser()
                    
                    if container.authRepository.isAdmin {
                        container.setAppState(.admin)
                    } else if container.authRepository.isAuthenticated {
                        container.setAppState(.main)
                        container.chatViewModel.listenToConversations()
                        container.notificationViewModel.startListening()
                        
                        async let location = container.locationService.requestLocation()
                        async let notification = container.notificationService.requestAuthorization()
                        async let executorRatings: () = container.executorViewModel.checkPendingRatings()
                        async let requesterRatings: () = container.requesterViewModel.checkPendingRatings()
                        _ = await (location, notification, executorRatings, requesterRatings)
                    }
                }
                .task(id: container.languageManager.currentLanguage) {
                    await container.lookupStore.loadLookup()
                }
                .environment(\.layoutDirection, container.languageManager.currentLanguage.layoutDirection)
                .environment(\.locale, container.languageManager.currentLanguage.locale)
                .environment(container)
                .preferredColorScheme(container.appearanceManager.currentMode.colorScheme)
                .id(container.languageManager.currentLanguage)
                .id(container.rootID)
        }
    }
}
