import Foundation

extension Date {
    func toRelativeString() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        formatter.locale = Locale.current
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}
