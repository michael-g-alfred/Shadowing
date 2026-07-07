import Foundation
import SwiftUI

@MainActor
@Observable
final class LanguageManager {

    static let shared = LanguageManager()

    private let storageKey = "AppLanguage"
    private(set) var currentLanguage: AppLanguage = .english

    private init() {
        setAppInitLanguage()
    }

    func setLanguage(_ language: AppLanguage) {
        currentLanguage = language
        UserDefaults.standard.set(language.rawValue, forKey: storageKey)
        let semanticContent: UISemanticContentAttribute = language == .arabic
            ? .forceRightToLeft
            : .forceLeftToRight
        UIView.appearance().semanticContentAttribute = semanticContent
    }

    func toggleLanguage() {
        setLanguage(currentLanguage == .english ? .arabic : .english)
    }

    private func setAppInitLanguage() {
        if let saved = UserDefaults.standard.string(forKey: storageKey),
           let language = AppLanguage(rawValue: saved) {
            setLanguage(language)
        } else {
            let code = Locale.current.language.languageCode?.identifier ?? "en"
            setLanguage(code.contains("ar") ? .arabic : .english)
        }
    }
}
