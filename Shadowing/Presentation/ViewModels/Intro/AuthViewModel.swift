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
    var phoneNumber: String = ""
    var selectedPhoneCountry: PhoneLookup?
    var bio: String = ""
    var selectedSpecialties: Set<TaskServiceLookup> = []
    var selectedCountry: CountryLookup? {
        didSet {
            guard oldValue?.id != selectedCountry?.id else { return }
            selectedGovernorate = nil
            if let selectedCountry {
                selectedPhoneCountry = lookupStore.phone(for: selectedCountry.id)
            }
        }
    }
    var selectedGovernorate: GovernorateLookup?
    
        // MARK: - State
    var isLoading = false
    
    private let authRepo: AuthRepositoryProtocol
    let lookupStore: LookupStore
    
    init(authRepo: AuthRepositoryProtocol, lookupStore: LookupStore) {
        self.authRepo = authRepo
        self.lookupStore = lookupStore
    }
    
    var isAdmin: Bool { authRepo.isAdmin }
    
        // MARK: - Lookup-derived data for the sign-up form
    var availableCountries: [CountryLookup] { lookupStore.countries }
    var availableGovernorates: [GovernorateLookup] {
        guard let selectedCountry else { return [] }
        return lookupStore.governorates(for: selectedCountry.id)
    }
    var availableSpecialties: [TaskServiceLookup] { lookupStore.services }
    var availablePhoneCodes: [PhoneLookup] { lookupStore.phone }
    
        // MARK: - Validation
    private var isPhoneNumberValid: Bool {
        let digitsOnly = phoneNumber.allSatisfy(\.isNumber)
        return digitsOnly && (6...14).contains(phoneNumber.count)
    }
    
    var isSignUpFormValid: Bool {
        password == confirmPassword
        && selectedCountry != nil
        && selectedGovernorate != nil
        && selectedPhoneCountry != nil
        && isPhoneNumberValid
    }
    
        // MARK: - Actions
    func loadLookupsIfNeeded() async {
        await lookupStore.loadLookup()
    }
    
    func signIn() async -> Bool {
        await performSubmit {
            try await self.authRepo.signIn(email: self.email, password: self.password)
        }
    }
    
    func signUp() async -> Bool {
        guard let selectedCountry, let selectedGovernorate, let selectedPhoneCountry else { return false }
        return await performSubmit {
            try await self.authRepo.signUp(
                email: self.email,
                password: self.password,
                displayName: self.displayName.trimmingCharacters(in: .whitespacesAndNewlines),
                nationalId: self.nationalID,
                countryId: selectedCountry.id,
                governorateId: selectedGovernorate.id,
                phoneCountryId: selectedPhoneCountry.id,
                phoneNumber: self.phoneNumber,
                bio: self.bio.trimmingCharacters(in: .whitespacesAndNewlines),
                specialtyIds: self.selectedSpecialties.map(\.id)
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
            AlertCenter.shared.showError(error.localizedDescription)
            return false
        }
    }
}
