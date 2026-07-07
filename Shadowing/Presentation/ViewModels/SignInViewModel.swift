import Foundation
import Observation

@MainActor
@Observable
final class SignInViewModel {
    var email = ""
    var password = ""
    
    var isLoading = false
    var errorMessage: String?

    private let authRepo: AuthRepositoryProtocol

    init(authRepo: AuthRepositoryProtocol) {
        self.authRepo = authRepo
    }

    var isFormValid: Bool {
        email.contains("@") && email.contains(".") && password.count >= 6
    }

    var isAdmin: Bool { authRepo.isAdmin }

    func submit() async -> Bool {
        isLoading = true
        defer { isLoading = false }
        do {
            try await authRepo.signIn(email: email, password: password)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
