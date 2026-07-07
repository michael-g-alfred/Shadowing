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
        
        DebugLogger.log("🚀 AuthRepository initialized")
    }
    
        // MARK: - Authentication
    
    func signIn(email: String, password: String) async throws {
        DebugLogger.log("══════════════════════════════════════")
        DebugLogger.log("🔐 Starting Sign In")
        DebugLogger.log("📧 Email: \(email)")
        
        let body = APIConfig.SigninBody(
            email: email,
            password: password
        )
        
        let config = APIConfig.signin(body)
        
        DebugLogger.log("🌐 Sending sign in request...")
        
        let response: APIResponseDTO<AuthResponse> = try await network.request(config)
        
        DebugLogger.log("✅ Sign In Successful")
        DebugLogger.log("👤 User: \(response.data.user.displayName)")
        DebugLogger.log("🎫 Access Token Received")
        DebugLogger.log("🔄 Refresh Token Received")
        
        persist(response.data)
        
        DebugLogger.log("🏁 Sign In Finished")
        DebugLogger.log("══════════════════════════════════════")
    }
    
    func signUp(
        email: String,
        password: String,
        displayName: String,
        nationalId: String
    ) async throws {
        
        DebugLogger.log("══════════════════════════════════════")
        DebugLogger.log("📝 Starting Sign Up")
        DebugLogger.log("📧 Email: \(email)")
        DebugLogger.log("👤 Name: \(displayName)")
        
        let body = APIConfig.SignupBody(
            email: email,
            password: password,
            displayName: displayName,
            nationalId: nationalId
        )
        
        let config = APIConfig.signup(body)
        
        DebugLogger.log("🌐 Sending sign up request...")
        
        let response: APIResponseDTO<AuthResponse> = try await network.request(config)
        
        DebugLogger.log("✅ Sign Up Successful")
        DebugLogger.log("👤 User: \(response.data.user.displayName)")
        
        persist(response.data)
        
        DebugLogger.log("🏁 Sign Up Finished")
        DebugLogger.log("══════════════════════════════════════")
    }
    
    func signOut() async throws {
        DebugLogger.log("══════════════════════════════════════")
        DebugLogger.log("🚪 Starting Sign Out")
        
        guard let refresh = keychainService.refreshToken else {
            DebugLogger.log("⚠️ No refresh token found")
            clearSession()
            return
        }
        
        DebugLogger.log("🔄 Refresh Token Found")
        
        let body = APIConfig.RefreshTokenBody(refreshToken: refresh)
        let config = APIConfig.signout(body)
        
        DebugLogger.log("🌐 Sending sign out request...")
        
        try? await network.requestWithoutResponse(config)
        
        DebugLogger.log("🗑️ Clearing local session")
        
        clearSession()
        
        DebugLogger.log("✅ Sign Out Complete")
        DebugLogger.log("══════════════════════════════════════")
    }
    
        // MARK: - Current User
    
    func loadCurrentUser() async throws {
        DebugLogger.log("📂 Loading current user from UserDefaults...")
        
        guard
            let data = UserDefaults.standard.data(forKey: DefaultsKey.user),
            let user = try? JSONDecoder().decode(UserModel.self, from: data)
        else {
            DebugLogger.log("⚠️ No cached user found")
            currentUser = nil
            return
        }
        
        currentUser = user
        
        DebugLogger.log("✅ Loaded User: \(user.displayName)")
    }
    
        // MARK: - Token
    
    func validAccessToken() async throws -> String? {
        
        DebugLogger.log("🔑 Checking Access Token")
        
        if let accessToken {
            DebugLogger.log("✅ Using cached access token")
            return accessToken
        }
        
        guard keychainService.refreshToken != nil else {
            DebugLogger.log("❌ No refresh token available")
            return nil
        }
        
        DebugLogger.log("🔄 Cached access token missing")
        DebugLogger.log("🌐 Refreshing token...")
        
        try await refreshTokenIfNeeded()
        
        DebugLogger.log("✅ New access token ready")
        
        return accessToken
    }
    
    private func refreshTokenIfNeeded() async throws {
        
        DebugLogger.log("══════════════════════════════════════")
        DebugLogger.log("🔄 Refresh Token Flow Started")
        
        guard let refresh = keychainService.refreshToken else {
            
            DebugLogger.log("❌ Missing refresh token")
            
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
        
        DebugLogger.log("🌐 Sending refresh request...")
        
        let response: APIResponseDTO<RefreshResponse> = try await network.request(config)
        
        accessToken = response.data.accessToken
        currentUser = response.data.user
        
        saveUserToDisk(response.data.user)
        
        DebugLogger.log("✅ Access Token Refreshed")
        DebugLogger.log("👤 Current User: \(response.data.user.displayName)")
        DebugLogger.log("══════════════════════════════════════")
    }
    
        // MARK: - Persistence
    
    private func persist(_ response: AuthResponse) {
        
        DebugLogger.log("💾 Persisting Authentication Data")
        
        accessToken = response.accessToken
        keychainService.refreshToken = response.refreshToken
        currentUser = response.user
        
        saveUserToDisk(response.user)
        
        DebugLogger.log("✅ Authentication Data Saved")
    }
    
    private func clearSession() {
        
        DebugLogger.log("🗑️ Clearing Session")
        
        accessToken = nil
        keychainService.clear()
        currentUser = nil
        
        UserDefaults.standard.removeObject(
            forKey: DefaultsKey.user
        )
        
        DebugLogger.log("✅ Session Cleared")
    }
    
    private func saveUserToDisk(_ user: UserModel?) {
        
        DebugLogger.log("💾 Saving User To Disk")
        
        guard let user else {
            DebugLogger.log("⚠️ User is nil")
            return
        }
        
        do {
            let data = try JSONEncoder().encode(user)
            
            UserDefaults.standard.set(
                data,
                forKey: DefaultsKey.user
            )
            
            DebugLogger.log("✅ User Saved")
            DebugLogger.log("👤 Name: \(user.displayName)")
            DebugLogger.log("🆔 ID: \(user.id)")
        } catch {
            DebugLogger.log("❌ Failed to encode user")
            DebugLogger.log("🚨 Error: \(error.localizedDescription)")
        }
    }
}

private enum DefaultsKey {
    static let user = "saved_user"
}
