import Foundation
import CoreLocation

struct MapTaskItem: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let budget: Double
    let latitude: Double
    let longitude: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct MapTasksPage: Codable {
    let tasks: [MapTaskItem]
    let nextCursor: String?
}
