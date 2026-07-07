import Foundation

struct APIResponseDTO<T: Codable>: Codable {
    let success: Bool
    let statusCode: Int
    let message: String
    let data: T
}
