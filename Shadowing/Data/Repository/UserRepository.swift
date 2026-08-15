import Foundation
import FirebaseFirestore
import MGNetworkingKit

@MainActor
@Observable
final class UserRepository: UserRepositoryProtocol {
    private(set) var currentUser: UserModel?
    private let network: MGNetworkServiceProtocol
    private let authRepository: AuthRepositoryProtocol
    
        // MARK: - Summary Cache
    private var summaryCache: [String: UserSummaryModel] = [:]
    private var inFlightSummaryRequests: [String: Task<UserSummaryModel, Error>] = [:]
    
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
        let fetchedUser = response.data.user.toDomain()
        
        if currentUser == nil || currentUser?.id == id {
            self.currentUser = fetchedUser
        }
        return fetchedUser
    }
    
        // MARK: - Summary (cached)
    func fetchUserSummary(id: String) async throws -> UserSummaryModel {
            // 1) Already cached — return immediately, no network call
        if let cached = summaryCache[id] {
            return cached
        }
        
            // 2) A request for this same id is already in flight (e.g. two
            // messages from the same sender arrived in the same snapshot
            // batch) — await that one instead of firing a duplicate.
        if let existingTask = inFlightSummaryRequests[id] {
            return try await existingTask.value
        }
        
        let task = Task<UserSummaryModel, Error> {
            let accessToken = try await getValidToken()
            let config = APIConfig.userSummary(id: id, accessToken: accessToken)
            let response: APIResponseDTO<UserSummaryResponseDTO> = try await network.request(config)
            return response.data.user.toDomain()
        }
        inFlightSummaryRequests[id] = task
        
        do {
            let user = try await task.value
            summaryCache[id] = user
            inFlightSummaryRequests[id] = nil
            return user
        } catch {
            inFlightSummaryRequests[id] = nil
            throw error
        }
    }
    
        /// Call this if a user's profile/avatar/name changes and you need
        /// fresh data on the next fetch (e.g. after editing your own profile).
    func invalidateSummaryCache(id: String? = nil) {
        if let id {
            summaryCache[id] = nil
        } else {
            summaryCache.removeAll()
        }
    }
    
    func fetchUserCount() async throws -> Int {
        let accessToken = try await getValidToken()
        let config = APIConfig.userCount(accessToken: accessToken)
        let response: APIResponseDTO<UserCountResponseDTO> = try await network.request(config)
        
        return response.data.count
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
    
        // MARK: - Specialty Suggestions
    
        /// Top-rated users registered under a given specialty (task_services id).
        /// Used to auto-suggest people to a requester right after they pick a
        /// service type while creating a task — no search, no invite, just a
        /// "here's who's around for this" preview.
    func fetchUsersBySpecialty(serviceId: Int, limit: Int? = nil) async throws -> [UserSummaryModel] {
        let accessToken = try await getValidToken()
        let config = APIConfig.usersBySpecialty(serviceId: serviceId, limit: limit, accessToken: accessToken)
        let response: APIResponseDTO<UsersBySpecialtyResponseDTO> = try await network.request(config)
        return response.data.users.map { $0.toDomain() }
    }
    
    func uploadAvatar(userId: String, imageData: Data, fileName: String, mimeType: String) async throws -> (avatarUrl: String, message: String, type: String) {
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
        invalidateSummaryCache(id: userId)
        
        return (
            avatarUrl: newAvatarUrl,
            message: response.message,
            type: response.type
        )
    }
    
        /// PATCH /users/:id — self-service profile edit (display name, bio,
        /// location, phone, specialties). Updates `currentUser` in place when
        /// editing your own profile, and invalidates the summary cache so any
        /// other screens showing this user's summary (chat, task cards, etc.)
        /// pick up the change on next fetch rather than showing stale data.
    func updateProfile(userId: String, payload: EditProfilePayload) async throws -> (user: UserModel, message: String, type: String) {
        let accessToken = try await getValidToken()
        let config = try APIConfig.updateProfile(userId: userId, payload: payload, accessToken: accessToken)
        let response: APIResponseDTO<ProfileResponseDTO> = try await network.request(config)
        let updatedUser = response.data.user.toDomain()
        
        if currentUser?.id == userId {
            self.currentUser = updatedUser
        }
        invalidateSummaryCache(id: userId)
        
        return (user: updatedUser, message: response.message, type: response.type)
    }
}

    // MARK: - DTO
    // Move this to your DTOs file if you keep them separate from the repository -
    // added here since UserSummaryResponseDTO / UserSummaryDTO's actual file
    // wasn't part of what I could see.
struct UsersBySpecialtyResponseDTO: Codable {
    let users: [UserSummaryDTO]
}
