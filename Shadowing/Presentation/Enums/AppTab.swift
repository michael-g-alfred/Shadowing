import Foundation

enum AppTab: String, CaseIterable, Identifiable {
    case map
    case home
    case chat
    case profile

    var id: String { rawValue }

    var title: LocalizedStringResource {
        switch self {
            case .map:      return "Map"
            case .home:     return "Home"
            case .chat:     return "Chat"
            case .profile:  return "Profile"
        }
    }

    var image: String {
        switch self {
            case .map:      return "map"
            case .home:     return "house"
            case .chat:     return "bubble.left.and.text.bubble.right"
            case .profile:  return "person"
        }
    }
}
