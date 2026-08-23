import SwiftUI
import FirebaseCore

/// The app's entry point.
///
/// `Shadowing` configures Firebase on launch, builds the single ``DIContainer`` instance that
/// backs the entire app, and performs the startup sequence responsible for restoring the
/// current user's session, determining the initial ``DIContainer/appState``, and kicking off
/// the concurrent tasks (location, push notifications, pending ratings) that should begin as
/// soon as a user is authenticated.
@main
struct Shadowing: App {

    /// The app-wide dependency container. Owned here as `@State` so its lifetime matches the
    /// app's and so SwiftUI observes changes to it and re-renders dependent views.
    @State private var container = DIContainer()

    /// Configures Firebase before any view or dependency in ``container`` is used.
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            container.makeRootView()
                .task {
                    // Attempt to restore the current user's session from the backend.
                    // A failure here (expired token, network blip) is non-fatal — we log it
                    // and fall through to the unauthenticated flow — but we no longer swallow
                    // it silently, so a transient error is distinguishable in logs.
                    do {
                        try await container.authRepository.loadCurrentUser()
                    } catch {
                        DebugLogger.log("⚠️ Session restore failed: \(error)")
                    }

                    if container.authRepository.isAdmin {
                        container.setAppState(.admin)
                    } else if container.authRepository.isAuthenticated {
                        container.setAppState(.main)
                        await container.startAuthenticatedSession()
                    }
                }
                .task(id: container.languageManager.currentLanguage.id) {
                    // Reloads lookup data whenever the active language changes, since lookup
                    // values (e.g. category names) are localized.
                    await container.lookupStore.loadLookup()
                }
                .environment(\.layoutDirection, container.languageManager.currentLanguage.layoutDirection)
                .environment(\.locale, container.languageManager.currentLanguage.locale)
                .environment(container)
                .preferredColorScheme(container.appearanceManager.currentMode.colorScheme)
                // Forces the view hierarchy to be rebuilt when the language changes, since
                // `layoutDirection`/`locale` environment changes alone don't always propagate
                // through already-materialized views (e.g. navigation stacks).
                .id(container.languageManager.currentLanguage)
                // A separate identity hook `DIContainer` can bump to force a full root reset
                // independent of language (e.g. after sign-out) without tearing down the app.
                .id(container.rootID)
        }
    }
}
