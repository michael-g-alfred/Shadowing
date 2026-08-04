import SwiftUI

@MainActor
@Observable
final class AppearanceManager {
    static let shared = AppearanceManager()

    private let storageKey = "appColorScheme"

    var currentMode: AppColorScheme {
        didSet {
            UserDefaults.standard.set(currentMode.rawValue, forKey: storageKey)
        }
    }

    private init() {
        if let raw = UserDefaults.standard.string(forKey: storageKey),
           let mode = AppColorScheme(rawValue: raw) {
            currentMode = mode
        } else {
            currentMode = .dark
        }
    }

    func setMode(_ mode: AppColorScheme) {
        currentMode = mode
    }
}
