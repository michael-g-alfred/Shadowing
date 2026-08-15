import Foundation

protocol UserRepositoryProtocol {
    func fetchUser(id: String) async throws -> UserModel
    func fetchUserSummary(id: String) async throws -> UserSummaryModel
    func fetchUserCount() async throws -> Int
    func fetchUserRatings(userId: String, cursor: String?, limit: Int?) async throws -> PaginatedRatingsResult
    func fetchUsersBySpecialty(serviceId: Int, limit: Int?) async throws -> [UserSummaryModel]
    func uploadAvatar(userId: String, imageData: Data, fileName: String, mimeType: String) async throws -> (avatarUrl: String, message: String, type: String)
    func updateProfile(userId: String, payload: EditProfilePayload) async throws -> (user: UserModel, message: String, type: String)
}
