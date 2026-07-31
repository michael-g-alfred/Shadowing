import Foundation

struct RatingModel: Identifiable, Profile {
    
    let id: String
    let rating: Int
    let comment: String
    let createdAt: Date
    let rater: UserSummaryModel
    
        // MARK: - Profile conformance (forwarded to the embedded rater)
    var displayName: String { rater.displayName }
    var avatarUrl: String? { rater.avatarUrl }
}

struct PaginatedRatingsResult {
    let ratings: [RatingModel]
    let hasMore: Bool
    let cursor: String?
}
