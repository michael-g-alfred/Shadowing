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
    var selectedCountry: Country? {
        didSet {
            guard oldValue != selectedCountry else { return }
            selectedGovernorate = nil
        }
    }
    var selectedGovernorate: Governorate?
    
        // MARK: - State
    var isLoading = false
    
    private let authRepo: AuthRepositoryProtocol
    
    init(authRepo: AuthRepositoryProtocol) {
        self.authRepo = authRepo
    }
    
    var isAdmin: Bool { authRepo.isAdmin }
    
        // MARK: - Validation
    var isSignUpFormValid: Bool {
        password == confirmPassword && selectedCountry != nil && selectedGovernorate != nil
    }
    
        // MARK: - Actions
    func signIn() async -> Bool {
        await performSubmit {
            try await self.authRepo.signIn(email: self.email, password: self.password)
        }
    }
    
    func signUp() async -> Bool {
        guard let selectedCountry, let selectedGovernorate else { return false }
        return await performSubmit {
            try await self.authRepo.signUp(
                email: self.email,
                password: self.password,
                displayName: self.displayName.trimmingCharacters(in: .whitespacesAndNewlines),
                nationalId: self.nationalID,
                country: selectedCountry,
                governorate: selectedGovernorate
            )
        }
    }
    
    private func performSubmit(_ operation: () async throws -> Void) async -> Bool {
        isLoading = true
        defer { isLoading = false }
        do {
            try await operation()
            return true
        } catch {
            AlertCenter.shared.showError(error)
            return false
        }
    }
}
