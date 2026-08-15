import Foundation
import CoreLocation

@MainActor
protocol LocationServiceProtocol: AnyObject {
    var currentLocation: CLLocation? { get }
    var authorizationStatus: CLAuthorizationStatus { get }
    func requestLocation()
}
