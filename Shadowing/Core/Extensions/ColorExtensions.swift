import SwiftUI

extension Color {
    
    init(lookupName: String) {
        switch lookupName.lowercased() {
            case "black":  self = .black
            case "blue":   self = .blue
            case "brown":  self = .brown
            case "clear":  self = .clear
            case "gray":   self = .gray
            case "green":  self = .green
            case "orange": self = .orange
            case "pink":   self = .pink
            case "purple": self = .purple
            case "red":    self = .red
            case "white":  self = .white
            case "yellow": self = .yellow
            default:
                self = .clear
        }
    }
}
