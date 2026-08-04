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
            default:       self = Color(hex: lookupName) ?? .gray
        }
    }
    
    private init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        let r, g, b, a: Double
        switch hexSanitized.count {
            case 6:
                r = Double((rgb >> 16) & 0xFF) / 255.0
                g = Double((rgb >> 8) & 0xFF) / 255.0
                b = Double(rgb & 0xFF) / 255.0
                a = 1.0
            case 8:
                r = Double((rgb >> 24) & 0xFF) / 255.0
                g = Double((rgb >> 16) & 0xFF) / 255.0
                b = Double((rgb >> 8) & 0xFF) / 255.0
                a = Double(rgb & 0xFF) / 255.0
            default:
                return nil
        }
        
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}
