import Foundation
import CoreLocation

struct MapBounds: Equatable, Codable {
    let minLat: Double
    let maxLat: Double
    let minLng: Double
    let maxLng: Double
}

struct MapTasksPage: Codable {
    let tasks: [TaskDTO]
    let truncated: Bool
}
