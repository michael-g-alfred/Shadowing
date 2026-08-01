import Foundation
import SwiftUI

enum AccountStatus: String, Codable {
    case active
    case suspended
    case deleted
    
    var localizedLabel: String {
        if LanguageManager.shared.currentLanguage == .arabic {
            switch self {
                case .active: return "نشط"
                case .suspended: return "موقوف مؤقتاً"
                case .deleted: return "محذوف"
            }
        } else {
            switch self {
                case .active: return "Active"
                case .suspended: return "Suspended"
                case .deleted: return "Deleted"
            }
        }
    }
    
    var color: Color {
        switch self {
            case .active: return .green
            case .suspended: return .orange
            case .deleted: return .red
        }
    }
}
