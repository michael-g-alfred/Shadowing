import Foundation
import Observation

@MainActor
@Observable
final class AuthViewModel {
    
        // MARK: - Shared Fields
    var email = ""
    var password = ""
    
        // MARK: - Sign Up Only Fields
    var displayName = ""
    var confirmPassword = ""
    var nationalID: String = ""
    
        // MARK: - State
    var isLoading = false
    var errorMessage: String?
    
    private let authRepo: AuthRepositoryProtocol
    
    init(authRepo: AuthRepositoryProtocol) {
        self.authRepo = authRepo
    }
    
    var isAdmin: Bool { authRepo.isAdmin }
    
        // MARK: - Validation
    private var isEmailValid: Bool {
        email.contains("@") && email.contains(".")
    }
    
    private var isPasswordValid: Bool {
        password.count >= 6
    }
    
    var isSignInFormValid: Bool {
        isEmailValid && isPasswordValid
    }
    
    var isSignUpFormValid: Bool {
        isEmailValid
        && isPasswordValid
        && !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && nationalID.count == 14
        && password == confirmPassword
    }
    
        // MARK: - Actions
    func signIn() async -> Bool {
        await performSubmit {
            try await self.authRepo.signIn(email: self.email, password: self.password)
        }
    }
    
    func signUp() async -> Bool {
        await performSubmit {
            try await self.authRepo.signUp(
                email: self.email,
                password: self.password,
                displayName: self.displayName.trimmingCharacters(in: .whitespacesAndNewlines),
                nationalId: self.nationalID
            )
        }
    }
    
    private func performSubmit(_ operation: () async throws -> Void) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await operation()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
