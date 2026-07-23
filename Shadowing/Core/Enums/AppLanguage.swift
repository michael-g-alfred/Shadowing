import Foundation
import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case arabic  = "ar"
    case english = "en"
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
            case .arabic:  return "العربية"
            case .english: return "English"
        }
    }
    
    var layoutDirection: LayoutDirection {
        self == .arabic ? .rightToLeft : .leftToRight
    }
    
    var locale: Locale {
        switch self {
            case .arabic:  return Locale(identifier: "ar_EG@numbers=arab")
            case .english: return Locale(identifier: "en_US")
        }
    }
}
