import Foundation

struct APIResponseDTO<T: Codable>: Codable {
    let code: Int
    let message: String
    let type: String
    let data: T
}
