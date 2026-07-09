import SwiftUI

struct AuthCoordinatorView: View {
    
    // MARK: - Environment
    @Environment(DIContainer.self) private var container
    
    // MARK: - State
    @State private var screen: AuthScreen = .signIn
    
    // MARK: - Body
    var body: some View {
        switch screen {
            case .signIn:
                container.makeSigninView(screen: $screen)
            case .signUp:
                container.makeSignupView(screen: $screen)
        }
    }
}
