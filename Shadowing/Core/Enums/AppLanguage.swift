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
    
    static var current: String {
        Locale.current.language.languageCode?.identifier ?? "en"
    }
}
