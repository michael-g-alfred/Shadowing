import SwiftUI

struct AuthCoordinatorView: View {
    
    @State private var screen: AuthScreen = .signIn
    @Environment(DIContainer.self) private var container
    
    var body: some View {
        switch screen {
            case .signIn:
                container.makeSigninView(screen: $screen)
            case .signUp:
                container.makeSignupView(screen: $screen)
        }
    }
}
