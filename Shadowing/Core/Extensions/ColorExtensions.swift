import SwiftUI

extension Color {
    init(lookupName: String) {
        switch lookupName.lowercased() {
            case "gray":   self = .gray
            case "blue":   self = .blue
            case "orange": self = .orange
            case "red":    self = .red
            case "purple": self = .purple
            case "green":  self = .green
            default:
                self = .clear
        }
    }
}
