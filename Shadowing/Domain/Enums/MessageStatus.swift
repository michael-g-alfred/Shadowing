import SwiftUI

enum MessageStatus: String, Hashable, Codable, Sendable {
    case sending
    case sent
    case delivered
    case read
    
        /// SF Symbol icon name for the status
    var iconName: String {
        switch self {
            case .sending:
                return "clock"
            case .sent:
                return "checkmark"
            case .delivered:
                return "checkmark.circle"
            case .read:
                return "checkmark.circle.fill"
        }
    }
    
        /// Tint color for the icon
    var iconColor: Color {
        switch self {
            case .sending, .sent, .delivered:
                return .gray
            case .read:
                return .secondary
        }
    }
}
