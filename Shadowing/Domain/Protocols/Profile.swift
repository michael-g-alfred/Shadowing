import Foundation

protocol Profile {
    var id: String { get }
    var displayName: String { get }
    var avatarUrl: String? { get }
}

extension Profile {
    var avatarUrl: String? { nil }
}
