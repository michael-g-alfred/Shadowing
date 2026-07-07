import Foundation

struct RatingModel: Identifiable, Equatable {
    let id: String
    let rating: Int
    let comment: String
    let raterId: String
    let raterName: String
    let createdAt: Date
}

struct PaginatedRatingsResult {
    let ratings: [RatingModel]
    let hasMore: Bool
    let cursor: String?
}
