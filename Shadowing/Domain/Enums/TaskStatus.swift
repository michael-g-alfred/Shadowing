import Foundation
import SwiftUI

enum TaskStatus: String, Codable {
    case published
    case pending
    case inProgress = "in_progress"
    case pendingCompleted = "pending_completed"
    case completed
    case cancelled
    
    var localizedLabel: String {
        if LanguageManager.shared.currentLanguage == .arabic {
            switch self {
                case .published: return "منشورة"
                case .pending: return "قيد الانتظار"
                case .inProgress: return "قيد التنفيذ"
                case .pendingCompleted: return "في انتظار التأكيد"
                case .completed: return "مكتملة"
                case .cancelled: return "مُلغاة"
            }
        } else {
            switch self {
                case .inProgress: return "In Progress"
                case .pendingCompleted: return "Pending Completed"
                default: return self.rawValue.capitalized
            }
        }
    }
    
    var color: Color {
        switch self {
            case .published: return .gray
            case .pending: return .blue
            case .inProgress: return .purple
            case .pendingCompleted: return .orange
            case .completed: return .green
            case .cancelled: return .red
        }
    }
}
