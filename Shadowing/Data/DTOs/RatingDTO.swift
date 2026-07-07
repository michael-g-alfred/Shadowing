import Foundation

struct RatingDTO: Codable {
    let id: String
    let rating: Int
    let comment: String
    let raterId: String
    let raterName: String
    let createdAt: String

    func toDomain() -> RatingModel {
        RatingModel(
            id: id,
            rating: rating,
            comment: comment,
            raterId: raterId,
            raterName: raterName,
            createdAt: createdAt.toDate() ?? Date()
        )
    }
}

struct RatingsDataDTO: Codable {
    let ratings: [RatingDTO]
    let hasMore: Bool
    let cursor: String?
}
