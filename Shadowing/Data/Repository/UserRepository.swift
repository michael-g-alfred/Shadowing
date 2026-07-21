import Foundation
import FirebaseFirestore
import MGNetworkingKit

@MainActor
@Observable
final class UserRepository: UserRepositoryProtocol {
    private(set) var currentUser: UserModel?
    private let network: MGNetworkServiceProtocol
    private let authRepository: AuthRepositoryProtocol
    
    init(network: MGNetworkServiceProtocol, authRepository: AuthRepositoryProtocol) {
        self.network = network
        self.authRepository = authRepository
    }
    
    private func getValidToken() async throws -> String {
        guard let token = try await authRepository.validAccessToken() else {
            DebugLogger.log("❌ getValidToken: no valid access token, throwing AuthError.noSession")
            throw AuthError.noSession
        }
        DebugLogger.log("🔑 getValidToken: token acquired (prefix: \(token.prefix(10))...)")
        return token
    }
    
    func fetchUser(id: String) async throws -> UserModel {
        DebugLogger.log("➡️ fetchUser called for id: \(id)")
        let accessToken = try await getValidToken()
        let config = APIConfig.user(id: id, accessToken: accessToken)
        let response: APIResponseDTO<ProfileResponseDTO> = try await network.request(config)
        let fetchedUser = response.data.user.toDomain()
        
        DebugLogger.log("✅ fetchUser succeeded for id: \(id) | displayName: \(fetchedUser.displayName)")
        
        if currentUser == nil || currentUser?.id == id {
            self.currentUser = fetchedUser
            DebugLogger.log("🔄 currentUser updated to: \(fetchedUser.displayName)")
        }
        return fetchedUser
    }
    
        // MARK: - Summary
    func fetchUserSummary(id: String) async throws -> UserSummaryModel {
        DebugLogger.log("➡️ fetchUserSummary called for id: \(id)")
        do {
            let accessToken = try await getValidToken()
            let config = APIConfig.userSummary(id: id, accessToken: accessToken)
            let response: APIResponseDTO<UserSummaryResponseDTO> = try await network.request(config)
            let user = response.data.user.toDomain()
            
            DebugLogger.log("✅ Fetched user summary: \(user)")
            
            return user
        } catch {
            DebugLogger.log("❌ fetchUserSummary FAILED for id: \(id) | error: \(error)")
            throw error
        }
    }
    
    func fetchUserCount() async throws -> Int {
        
        let accessToken = try await getValidToken()
        let config = APIConfig.userCount(accessToken: accessToken)
        let response: APIResponseDTO<UserCountResponseDTO> = try await network.request(config)
        
        return response.data.count
    }
    
    func fetchUserRatings(userId: String, cursor: String?, limit: Int?) async throws -> PaginatedRatingsResult {
        DebugLogger.log("➡️ fetchUserRatings called for userId: \(userId)")
        let accessToken = try await getValidToken()
        let config = APIConfig.userRatings(userId: userId, cursor: cursor, limit: limit, accessToken: accessToken)
        let response: APIResponseDTO<RatingsDataDTO> = try await network.request(config)
        return PaginatedRatingsResult(
            ratings: response.data.ratings.map { $0.toDomain() },
            hasMore: response.data.hasMore,
            cursor: response.data.cursor
        )
    }
    
    func uploadAvatar(userId: String, imageData: Data, fileName: String, mimeType: String) async throws -> String {
        let accessToken = try await getValidToken()
        let config = APIConfig.uploadAvatar(
            userId: userId,
            imageData: imageData,
            fileName: fileName,
            mimeType: mimeType,
            accessToken: accessToken
        )
        let response: APIResponseDTO<AvatarUploadResponseDTO> = try await network.request(config)
        let newAvatarUrl = response.data.avatarUrl
        
        if var updatedUser = currentUser, updatedUser.id == userId {
            updatedUser.avatarUrl = newAvatarUrl
            self.currentUser = updatedUser
        }
        return newAvatarUrl
    }
}
