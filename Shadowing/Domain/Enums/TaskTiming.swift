import Foundation

enum TaskTiming: String, CaseIterable, Identifiable {
    case now
    case scheduled

    var id: String { rawValue }

    var title: LocalizedStringResource {
        switch self {
            case .now:       return "Now"
            case .scheduled: return "Scheduled"
        }
    }
}
