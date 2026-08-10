import Foundation

enum AppTab: String, CaseIterable, Identifiable {
    case home
    case map
    case chats
    case notifications
    case profile
    
    var id: String { rawValue }
    
    var title: LocalizedStringResource {
        switch self {
            case .home:           return "Home"
            case .map:            return "Map"
            case .chats:          return "Chats"
            case .notifications:  return "Notifications"
            case .profile:        return "Profile"
        }
    }
    
    var image: String {
        switch self {
            case .home:           return "house"
            case .map:            return "map"
            case .chats:          return "bubble.left.and.text.bubble.right"
            case .notifications:  return "bell"
            case .profile:        return "person"
        }
    }
}
