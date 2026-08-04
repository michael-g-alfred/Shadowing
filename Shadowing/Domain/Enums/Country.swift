import Foundation

enum Country: Int, Codable, CaseIterable {
    case egypt = 1
    case saudiArabia = 2
    case uae = 3
    
    /// ISO 3166-1 alpha-2 code, matches the backend's `countries.code`.
    var code: String {
        switch self {
            case .egypt: return "EG"
            case .saudiArabia: return "SA"
            case .uae: return "AE"
        }
    }
    
    var localizedLabel: String {
        if LanguageManager.shared.currentLanguage == .arabic {
            switch self {
                case .egypt: return "مصر"
                case .saudiArabia: return "السعودية"
                case .uae: return "الإمارات"
            }
        } else {
            switch self {
                case .egypt: return "Egypt"
                case .saudiArabia: return "Saudi Arabia"
                case .uae: return "United Arab Emirates"
            }
        }
    }
}
