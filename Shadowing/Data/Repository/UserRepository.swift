import Foundation
import FirebaseFirestore
import MGNetworkingKit

/// Handles user profile fetch/update, plus an in-memory cache and
/// request-deduplication layer for lightweight ``UserSummaryModel`` lookups.
///
/// The summary cache exists mainly to serve `ChatRepository`, which needs to
/// resolve the same sender/participant summaries repeatedly (often several
/// times concurrently within a single Firestore snapshot resolution) without
/// hammering the network.
@MainActor
@Observable
final class UserRepository: UserRepositoryProtocol {

    /// The full profile of the signed-in user, if loaded.
    private(set) var currentUser: UserModel?

    /// Networking layer used to perform REST requests.
    private let network: MGNetworkServiceProtocol

    /// Auth repository used to obtain a valid access token for each request.
    private let authRepository: AuthRepositoryProtocol

    // MARK: - Summary Cache

    /// Cache of previously fetched user summaries, keyed by user ID.
    private var summaryCache: [String: UserSummaryModel] = [:]

    /// In-flight summary fetch tasks, keyed by user ID, used to
    /// deduplicate concurrent requests for the same user.
    private var inFlightSummaryRequests: [String: Task<UserSummaryModel, Error>] = [:]

    /// Creates a user repository.
    ///
    /// - Parameters:
    ///   - network: Networking service used to perform REST requests.
    ///   - authRepository: Auth repository used to obtain access tokens.
    init(network: MGNetworkServiceProtocol, authRepository: AuthRepositoryProtocol) {
        self.network = network
        self.authRepository = authRepository
    }

    /// Obtains a valid access token, throwing if there is no active session.
    ///
    /// - Returns: A valid access token.
    /// - Throws: ``AuthError/noSession`` if there is no signed-in user.
    private func getValidToken() async throws -> String {
        guard let token = try await authRepository.validAccessToken() else {
            throw AuthError.noSession
        }
        return token
    }

    /// Fetches a user's full profile.
    ///
    /// Updates ``currentUser`` if the fetched user is (or becomes) the
    /// signed-in user.
    ///
    /// - Parameter id: The user's ID.
    /// - Returns: The fetched ``UserModel``.
    /// - Throws: A networking error, or ``AuthError/noSession``.
    func fetchUser(id: String) async throws -> UserModel {
        let accessToken = try await getValidToken()
        let config = APIConfig.user(id: id, accessToken: accessToken)
        let response: APIResponseDTO<UserResponseDTO> = try await network.request(config)
        let fetchedUser = response.data.user.toDomain()

        if currentUser == nil || currentUser?.id == id {
            self.currentUser = fetchedUser
        }
        return fetchedUser
    }

    // MARK: - Summary (cached)

    /// Fetches a lightweight ``UserSummaryModel``, using an in-memory cache
    /// and de-duplicating concurrent requests for the same ID.
    ///
    /// Lookup order:
    /// 1. Return the cached summary immediately, if present.
    /// 2. If a request for this ID is already in flight, await that request
    ///    instead of firing a duplicate.
    /// 3. Otherwise, start a new fetch, cache the result on success, and
    ///    clear the in-flight marker either way.
    ///
    /// - Parameter id: The user's ID.
    /// - Returns: The user's ``UserSummaryModel``.
    /// - Throws: A networking error, or ``AuthError/noSession``.
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

    /// Invalidates cached user summaries.
    ///
    /// Call this whenever a user's profile, avatar, or name changes so the
    /// next ``fetchUserSummary(id:)`` call gets fresh data instead of a
    /// stale cached copy (e.g. after editing your own profile).
    ///
    /// - Parameter id: The specific user ID to invalidate, or `nil` to clear
    ///   the entire cache.
    func invalidateSummaryCache(id: String? = nil) {
        if let id {
            summaryCache[id] = nil
        } else {
            summaryCache.removeAll()
        }
    }

    /// Fetches the total number of registered users.
    ///
    /// - Returns: The total user count.
    /// - Throws: A networking error, or ``AuthError/noSession``.
    func fetchUserCount() async throws -> Int {
        let accessToken = try await getValidToken()
        let config = APIConfig.userCount(accessToken: accessToken)
        let response: APIResponseDTO<UserCountResponseDTO> = try await network.request(config)

        return response.data.count
    }

    /// Fetches a page of ratings left for a given user.
    ///
    /// - Parameters:
    ///   - userId: The user whose ratings to fetch.
    ///   - cursor: An opaque pagination cursor from a previous call, or
    ///     `nil` to fetch the first page.
    ///   - limit: Maximum number of ratings to return.
    /// - Returns: A ``PaginatedRatingsResult`` containing the ratings page,
    ///   a `hasMore` flag, and the next cursor.
    /// - Throws: A networking error, or ``AuthError/noSession``.
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

    /// Fetches users matching a given specialty, for executor suggestions.
    ///
    /// - Parameters:
    ///   - serviceId: Lookup ID of the specialty/service type.
    ///   - limit: Maximum number of users to return.
    /// - Returns: An array of matching ``UserSummaryModel``s.
    /// - Throws: A networking error, or ``AuthError/noSession``.
    func fetchUsersBySpecialty(serviceId: Int, limit: Int? = nil) async throws -> [UserSummaryModel] {
        let accessToken = try await getValidToken()
        let config = APIConfig.usersBySpecialty(serviceId: serviceId, limit: limit, accessToken: accessToken)
        let response: APIResponseDTO<UsersBySpecialtyResponseDTO> = try await network.request(config)
        return response.data.users.map { $0.toDomain() }
    }

    /// Uploads a new avatar image for a user.
    ///
    /// Updates ``currentUser``'s avatar URL if `userId` matches the
    /// signed-in user, and invalidates that user's cached summary.
    ///
    /// - Parameters:
    ///   - userId: The user whose avatar is being updated.
    ///   - imageData: Raw image data to upload.
    ///   - fileName: The file name to associate with the upload.
    ///   - mimeType: The image's MIME type.
    /// - Returns: A tuple of the new avatar URL, a server message, and a
    ///   message type.
    /// - Throws: A networking error, or ``AuthError/noSession``.
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

    /// Updates a user's profile.
    ///
    /// Updates ``currentUser`` if `userId` matches the signed-in user, and
    /// invalidates that user's cached summary.
    ///
    /// - Parameters:
    ///   - userId: The user whose profile is being updated.
    ///   - payload: The fields to update.
    /// - Returns: A tuple of the updated ``UserModel``, a server message,
    ///   and a message type.
    /// - Throws: A networking or encoding error, or ``AuthError/noSession``.
    func updateProfile(userId: String, payload: EditProfilePayload) async throws -> (user: UserModel, message: String, type: String) {
        let accessToken = try await getValidToken()
        let config = try APIConfig.updateProfile(userId: userId, payload: payload, accessToken: accessToken)
        let response: APIResponseDTO<UserResponseDTO> = try await network.request(config)
        let updatedUser = response.data.user.toDomain()

        if currentUser?.id == userId {
            self.currentUser = updatedUser
        }
        invalidateSummaryCache(id: userId)

        return (user: updatedUser, message: response.message, type: response.type)
    }
}
