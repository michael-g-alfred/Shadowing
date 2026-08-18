import Foundation

extension String {
    
    private static let isoFormatterWithFractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    private static let isoFormatterWithoutFractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
    
    func toDate() -> Date? {
        if let date = Self.isoFormatterWithFractional.date(from: self) {
            return date
        }
        return Self.isoFormatterWithoutFractional.date(from: self)
    }
}
