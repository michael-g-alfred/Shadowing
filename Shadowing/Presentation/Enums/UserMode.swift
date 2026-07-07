import Foundation

enum UserMode: String, Identifiable {
    case requester
    case executor

    var id: String { rawValue }

    var title: LocalizedStringResource {
        switch self {
            case .requester: return "Requester"
            case .executor:  return "Executor"
        }
    }

    var navigationTitle: LocalizedStringResource {
        switch self {
            case .requester: return "Requester's Mode"
            case .executor:  return "Executor's Mode"
        }
    }

    var image: String {
        switch self {
            case .requester: return "arrow.up.doc.fill"
            case .executor:  return "arrow.down.doc.fill"
        }
    }
}
