import SwiftUI

enum AlertType {
    case success
    case error
    case warning
    case info
    
    var label: String {
        if LanguageManager.shared.currentLanguage == .arabic {
            switch self {
                case .success: return "نجاح"
                case .error:   return "خطأ"
                case .warning: return "تنبيه"
                case .info:    return "معلومة"
            }
        } else {
            switch self {
                case .success: return "Success"
                case .error:   return "Error"
                case .warning: return "Warning"
                case .info:    return "Information"
            }
        }
    }
}

extension AlertType {
        /// Maps the backend's `APIResponseDTO.type` string ("success" / "warning"
        /// / "error" / "fail" / ...) to the local alert type. Unknown values
        /// fall back to `.info` rather than crashing.
    init(responseType: String) {
        switch responseType.lowercased() {
            case "success":
                self = .success
            case "warning":
                self = .warning
            case "error", "fail", "failed":
                self = .error
            default:
                self = .info
        }
    }
}
