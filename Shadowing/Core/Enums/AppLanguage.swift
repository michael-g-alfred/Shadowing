import Foundation
import SwiftUI

/// The languages supported by the app's in-app localization system.
///
/// Distinct from the device's system language: the user picks one of these from Settings,
/// and ``DIContainer/languageManager`` applies the corresponding locale and layout direction
/// to the entire app.
enum AppLanguage: String, CaseIterable, Identifiable {
    /// Arabic, displayed right-to-left with Arabic-indic numerals.
    case arabic  = "ar"
    /// English, displayed left-to-right.
    case english = "en"
    /// French, displayed left-to-right.
    case french  = "fr"

    var id: String { rawValue }

    /// The localized, user-facing name of this language.
    var title: LocalizedStringResource {
        switch self {
            case .arabic:  return "Arabic"
            case .english: return "English"
            case .french:  return "French"
        }
    }

    /// The layout direction the app should use when this language is active.
    var layoutDirection: LayoutDirection {
        self == .arabic ? .rightToLeft : .leftToRight
    }

    /// The `Locale` applied for date, number, and string formatting when this language is
    /// active.
    ///
    /// Arabic uses `ar_EG@numbers=arab` to render Arabic-indic digits rather than Western
    /// numerals.
    var locale: Locale {
        switch self {
            case .arabic:  return Locale(identifier: "ar_EG@numbers=arab")
            case .english: return Locale(identifier: "en_US")
            case .french:  return Locale(identifier: "fr_FR")
        }
    }
}
