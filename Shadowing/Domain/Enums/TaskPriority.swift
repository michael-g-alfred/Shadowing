import Foundation
import SwiftUI

enum TaskPriority: String, Codable, CaseIterable {
    case low
    case normal
    case high
    case urgent
    
    var localizedLabel: String {
        if LanguageManager.shared.currentLanguage == .arabic {
            switch self {
                case .low: return "منخفضة"
                case .normal: return "عادية"
                case .high: return "عالية"
                case .urgent: return "عاجلة"
            }
        } else {
            return self.rawValue.capitalized
        }
    }
    
    var color: Color {
        switch self {
            case .low: return .gray
            case .normal: return .blue
            case .high: return .orange
            case .urgent: return .red
        }
    }
    
    var icon: String {
        switch self {
            case .low: return "arrow.down.circle.fill"
            case .normal: return "minus.circle.fill"
            case .high: return "arrow.up.circle.fill"
            case .urgent: return "flame.fill"
        }
    }
}
