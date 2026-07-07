import Foundation
import SwiftUI

struct TaskPriorityModel: Identifiable, Hashable, Sendable {
    let id: Int
    let name: String
    let labelAr: String
    let labelEn: String
    let color: String
    let icon: String
}

extension TaskPriorityModel {
    var localizedLabel: String {
        if AppLanguage.current == "ar" {
            "\(labelAr)"
        } else {
            "\(labelEn)"
        }
    }
}

extension TaskPriorityModel {
    var colorStyle: Color {
        switch color.lowercased() {
            case "gray":
                return .gray
            case "blue":
                return .blue
            case "orange":
                return .orange
            case "red":
                return .red
            default:
                return .gray
        }
    }
}
