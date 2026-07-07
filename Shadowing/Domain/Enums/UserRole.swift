import Foundation

enum UserRole: Int, CaseIterable {
    case user = 1
    case admin = 2

    var name: String {
        switch self {
        case .user: return "user"
        case .admin: return "admin"
        }
    }

    var labelAr: String {
        switch self {
        case .user: return "مستخدم"
        case .admin: return "أدمن"
        }
    }

    var labelEn: String {
        switch self {
        case .user: return "User"
        case .admin: return "Admin"
        }
    }
}

extension UserRole: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        guard let value = UserRole.allCases.first(where: { $0.name == raw }) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unknown UserRole: \(raw)"
            )
        }
        self = value
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(name)
    }
}
