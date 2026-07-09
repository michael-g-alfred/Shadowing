import Foundation
import MGNetworkingKit

@MainActor
@Observable
final class UserRepository: UserRepositoryProtocol {
    
    private let network: MGNetworkServiceProtocol
    private let authRepository: AuthRepositoryProtocol
    
    init(network: MGNetworkServiceProtocol, authRepository: AuthRepositoryProtocol) {
        self.network = network
        self.authRepository = authRepository
    }
    
    private func getValidToken() async throws -> String {
        guard let token = try await authRepository.validAccessToken() else {
            throw AuthError.noSession
        }
        return token
    }
    
    func fetchUser(id: String) async throws -> UserModel {
        let accessToken = try await getValidToken()
        let config = APIConfig.user(id: id, accessToken: accessToken)
        let response: APIResponseDTO<ProfileResponseDTO> = try await network.request(config)
        return response.data.user.toDomain()
    }
    
    func fetchUserCount() async throws -> Int {
        return 1
    }
    
    func fetchUserRatings(userId: String, cursor: String?, limit: Int?) async throws -> PaginatedRatingsResult {
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
        return response.data.avatarUrl
    }
}
