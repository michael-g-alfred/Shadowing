import Foundation
import Observation

@MainActor
@Observable
final class SignUpViewModel {
    var displayName = ""
    var email = ""
    var password = ""
    var confirmPassword = ""
    var nationalIDCells: [String] = Array(repeating: "", count: 14)
    
    var isLoading = false
    var errorMessage: String?

    private let authRepo: AuthRepositoryProtocol

    init(authRepo: AuthRepositoryProtocol) {
        self.authRepo = authRepo
    }

    var isFormValid: Bool {
        let fullID = nationalIDCells.joined()
        return !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && email.contains("@") && email.contains(".")
            && fullID.count == 14
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
                nationalId: nationalIDCells.joined()
            )
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
