import Foundation

protocol UserRepositoryProtocol {
    func fetchUser(id: String) async throws -> UserModel
    func fetchUserCount() async throws -> Int
    func fetchUserRatings(userId: String, cursor: String?, limit: Int?) async throws -> PaginatedRatingsResult
}
