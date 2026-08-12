import Foundation
import Observation
import MGNetworkingKit

@MainActor
@Observable
final class AuthRepository: AuthRepositoryProtocol {
    
    var isAuthenticated: Bool { currentUser != nil }
    var isAdmin: Bool { currentUser?.isAdmin ?? false }
    
    private(set) var accessToken: String?
    private(set) var currentUser: UserModel?
    
    private let network: MGNetworkServiceProtocol
    private let keychainService: KeychainService
    
    init(
        network: MGNetworkServiceProtocol,
        keychainService: KeychainService
    ) {
        self.network = network
        self.keychainService = keychainService
    }
    
        // MARK: - Authentication
    
    func signIn(email: String, password: String) async throws {
        let body = APIConfig.SigninBody(
            email: email,
            password: password
        )
        
        let config = APIConfig.signin(body)
        let response: APIResponseDTO<AuthResponse> = try await network.request(config)
        
        persist(response.data)
    }
    
    func signUp(
        email: String,
        password: String,
        displayName: String,
        nationalId: String,
        countryId: Int,
        governorateId: Int,
        phoneCountryId: Int,
        phoneNumber: String,
        bio: String,
        specialtyIds: [Int]
    ) async throws {
        let body = APIConfig.SignupBody(
            email: email,
            password: password,
            displayName: displayName,
            nationalId: nationalId,
            phoneCountryId: phoneCountryId,
            phoneNumber: phoneNumber,
            countryId: countryId,
            governorateId: governorateId,
            bio: bio,
            specialtyIds: specialtyIds
        )
        
        let config = APIConfig.signup(body)
        let response: APIResponseDTO<AuthResponse> = try await network.request(config)
        
        persist(response.data)
    }
    
    func signOut() async throws {
        guard let refresh = keychainService.refreshToken else {
            clearSession()
            return
        }
        
        let body = APIConfig.RefreshTokenBody(refreshToken: refresh)
        let config = APIConfig.signout(body)
        
        try? await network.requestWithoutResponse(config)
        clearSession()
    }
    
        // MARK: - Current User
    
    func loadCurrentUser() async throws {
        guard
            let data = UserDefaults.standard.data(forKey: DefaultsKey.user),
            let user = try? JSONDecoder().decode(UserModel.self, from: data)
        else {
            currentUser = nil
            return
        }
        
        currentUser = user
    }
    
        // MARK: - Token
    
    func validAccessToken() async throws -> String? {
        if let accessToken {
            return accessToken
        }
        
        guard keychainService.refreshToken != nil else {
            return nil
        }
        
        try await refreshTokenIfNeeded()
        return accessToken
    }
    
    private func refreshTokenIfNeeded() async throws {
        guard let refresh = keychainService.refreshToken else {
            clearSession()
            throw AuthError.server(
                statusCode: 401,
                message: "No refresh token"
            )
        }
        
        let body = APIConfig.RefreshTokenBody(
            refreshToken: refresh
        )
        
        let config = APIConfig.refresh(body)
        let response: APIResponseDTO<RefreshResponse> = try await network.request(config)
        
        accessToken = response.data.accessToken
        currentUser = response.data.user
        
        saveUserToDisk(response.data.user)
    }
    
        // MARK: - Persistence
    
    private func persist(_ response: AuthResponse) {
        accessToken = response.accessToken
        keychainService.refreshToken = response.refreshToken
        currentUser = response.user
        
        saveUserToDisk(response.user)
    }
    
    private func clearSession() {
        accessToken = nil
        keychainService.clear()
        currentUser = nil
        
        UserDefaults.standard.removeObject(
            forKey: DefaultsKey.user
        )
    }
    
    private func saveUserToDisk(_ user: UserModel?) {
        guard let user else { return }
        
        do {
            let data = try JSONEncoder().encode(user)
            
            UserDefaults.standard.set(
                data,
                forKey: DefaultsKey.user
            )
        } catch {}
    }
}

private enum DefaultsKey {
    static let user = "saved_user"
}
