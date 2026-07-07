import Foundation

struct UserModel: Codable, Identifiable, Equatable, Profile {
    let id: String
    let email: String
    let displayName: String
    let nationalId: String?
    let role: String
    let rating: Double
    let totalRatings: Int
    let completedTasks: Int
    let createdAt: Date?
    
    var isAdmin: Bool { role.lowercased() == "admin" }
}
