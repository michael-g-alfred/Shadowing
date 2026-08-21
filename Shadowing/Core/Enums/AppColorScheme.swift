import SwiftUI

/// The app's user-selectable appearance mode, shown as an option in Settings.
enum AppColorScheme: String, CaseIterable, Identifiable {
    /// Always use the light appearance.
    case light
    /// Always use the dark appearance.
    case dark
    /// Follow the device's current appearance setting.
    case system

    var id: String { rawValue }

    /// The localized, user-facing name of this mode.
    var title: LocalizedStringResource {
        switch self {
            case .light: return "Light"
            case .dark: return "Dark"
            case .system: return "System"
        }
    }

    /// The SF Symbol representing this mode in the settings UI.
    var icon: String {
        switch self {
            case .light: return "sun.max.fill"
            case .dark: return "moon.fill"
            case .system: return "circle.righthalf.filled"
        }
    }

    /// The `ColorScheme` to apply via `.preferredColorScheme(_:)`.
    ///
    /// Returns `nil` for ``system``, which tells SwiftUI to defer to the device's setting
    /// rather than forcing light or dark.
    var colorScheme: ColorScheme? {
        switch self {
            case .light: return .light
            case .dark: return .dark
            case .system: return nil
        }
    }
}
