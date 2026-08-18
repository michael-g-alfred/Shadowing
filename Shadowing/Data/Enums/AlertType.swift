import SwiftUI

enum AlertType {
    case success
    case error
    case warning
    case info
    
    var label: LocalizedStringResource {
        switch self {
            case .success: return "Success"
            case .error:   return "Error"
            case .warning: return "Warning"
            case .info:    return "Information"
        }
    }
}

extension AlertType {
    
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
