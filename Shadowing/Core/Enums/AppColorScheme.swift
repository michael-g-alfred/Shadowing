import SwiftUI

enum AppColorScheme: String, CaseIterable, Identifiable {
    case light
    case dark
    case system
    
    var id: String { rawValue }
    
    var title: String {
        if LanguageManager.shared.currentLanguage == .arabic {
            switch self {
                case .light: return "فاتح"
                case .dark: return "داكن"
                case .system: return "تلقائي"
            }
        } else {
            switch self {
                case .light: return "Light"
                case .dark: return "Dark"
                case .system: return "System"
            }
        }
    }
    
    var icon: String {
        switch self {
            case .light: return "sun.max.fill"
            case .dark: return "moon.fill"
            case .system: return "circle.righthalf.filled"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
            case .light: return .light
            case .dark: return .dark
            case .system: return nil
        }
    }
}
