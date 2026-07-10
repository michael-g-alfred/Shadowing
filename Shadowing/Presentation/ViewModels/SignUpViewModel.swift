import Foundation
import Observation

@MainActor
@Observable
final class SignUpViewModel {
    var displayName = ""
    var email = ""
    var password = ""
    var confirmPassword = ""
    var nationalID: String = ""
    
    var isLoading = false
    var errorMessage: String?
    
    private let authRepo: AuthRepositoryProtocol
    
    init(authRepo: AuthRepositoryProtocol) {
        self.authRepo = authRepo
    }
    
    var isFormValid: Bool {
        return !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && email.contains("@") && email.contains(".")
        && nationalID.count == 14
        && password.count >= 6
        && password == confirmPassword
    }
    
    func submit() async -> Bool {
        isLoading = true
        defer { isLoading = false }
        do {
            try await authRepo.signUp(
                email: email,
                password: password,
                displayName: displayName.trimmingCharacters(in: .whitespacesAndNewlines),
                nationalId: nationalID
            )
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
