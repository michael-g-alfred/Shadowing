import Foundation

/// Wire format for a map-viewport task query, decoded inside the repository
/// and mapped to ``MapTasksPage`` before crossing the domain boundary.
struct MapTasksPageDTO: Codable {
    let tasks: [TaskDTO]
    let truncated: Bool
}
