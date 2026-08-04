import Foundation

extension String {
        /// Parses an ISO8601 timestamp string (as returned by the API) into a Date.
        /// Handles both with and without fractional seconds.
    func toDate() -> Date? {
        let withFractional = ISO8601DateFormatter()
        withFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = withFractional.date(from: self) {
            return date
        }
        
        let withoutFractional = ISO8601DateFormatter()
        withoutFractional.formatOptions = [.withInternetDateTime]
        return withoutFractional.date(from: self)
    }
}

extension String: @retroactive Identifiable {
    public var id: String { self }
}
