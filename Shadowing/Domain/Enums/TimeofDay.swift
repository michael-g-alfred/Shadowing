import Foundation

enum PreferredTimeOfDay: String, Codable, CaseIterable {
    case morning
    case midday
    case afternoon
    case evening
    
    var localizedLabel: String {
        if LanguageManager.shared.currentLanguage == .arabic {
            switch self {
                case .morning: return "صباحاً"
                case .midday: return "ظهراً"
                case .afternoon: return "بعد الظهر"
                case .evening: return "مساءً"
            }
        } else {
            return self.rawValue.capitalized
        }
    }
    
    var localizedSubtitle: String {
        if LanguageManager.shared.currentLanguage == .arabic {
            switch self {
                case .morning: return "قبل ١٠ صباحاً"
                case .midday: return "١٠ صباحاً - ٢ ظهراً"
                case .afternoon: return "٢ ظهراً - ٦ مساءً"
                case .evening: return "بعد ٦ مساءً"
            }
        } else {
            switch self {
                case .morning: return "Before 10am"
                case .midday: return "10am - 2pm"
                case .afternoon: return "2pm - 6pm"
                case .evening: return "After 6pm"
            }
        }
    }
    
    var iconName: String {
        switch self {
            case .morning: return "sunrise"
            case .midday: return "sun.max"
            case .afternoon: return "sunset"
            case .evening: return "moon.stars"
        }
    }
}
