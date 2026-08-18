import Foundation
import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case arabic  = "ar"
    case english = "en"
    case french  = "fr"
    
    var id: String { rawValue }
    
    var title: LocalizedStringResource {
        switch self {
            case .arabic:  return "Arabic"
            case .english: return "English"
            case .french:  return "French"
        }
    }
    
    var layoutDirection: LayoutDirection {
        self == .arabic ? .rightToLeft : .leftToRight
    }
    
    var locale: Locale {
        switch self {
            case .arabic:  return Locale(identifier: "ar_EG@numbers=arab")
            case .english: return Locale(identifier: "en_US")
            case .french:  return Locale(identifier: "fr_FR")
        }
    }
}
