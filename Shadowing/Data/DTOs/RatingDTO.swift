import Foundation

struct RatingDTO: Codable {
    let id: String
    let rating: Int
    let comment: String
    let createdAt: String
    let rater: UserSummaryDTO
    
    func toDomain() -> RatingModel {
        RatingModel(
            id: id,
            rating: rating,
            comment: comment,
            createdAt: createdAt.toDate() ?? Date(),
            rater: rater.toDomain()
        )
    }
}

struct RatingsDataDTO: Codable {
    let ratings: [RatingDTO]
    let hasMore: Bool
    let cursor: String?
}
