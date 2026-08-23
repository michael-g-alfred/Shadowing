import Foundation
import CoreLocation

struct MapBounds: Equatable, Codable {
    let minLat: Double
    let maxLat: Double
    let minLng: Double
    let maxLng: Double
}

/// Domain result of a map-viewport task query. Tasks are already mapped to
/// domain models and pre-filtered to those with a valid coordinate.
struct MapTasksPage {
    let tasks: [TaskModel]
    let truncated: Bool
}
