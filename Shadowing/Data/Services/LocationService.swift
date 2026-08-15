import Foundation
import CoreLocation

@MainActor
@Observable
final class LocationService: NSObject, LocationServiceProtocol {
    
    private(set) var currentLocation: CLLocation?
    private(set) var authorizationStatus: CLAuthorizationStatus
    
    private let manager = CLLocationManager()
    
    override init() {
        self.authorizationStatus = CLLocationManager().authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }
    
    func requestLocation() {
        switch manager.authorizationStatus {
            case .notDetermined:
                manager.requestWhenInUseAuthorization()
            case .authorizedWhenInUse, .authorizedAlways:
                manager.requestLocation()
            default:
                break
        }
    }
    
    func getCurrentLocation() async -> CLLocation? {
        return currentLocation
    }
}

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus
            if manager.authorizationStatus == .authorizedWhenInUse
                || manager.authorizationStatus == .authorizedAlways {
                manager.requestLocation()
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        Task { @MainActor in
            currentLocation = loc
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
            // Swallow — AddTaskVM treats a missing location as optional lat/lng
    }
}

#if DEBUG
@MainActor
final class PreviewLocationService: LocationServiceProtocol {
    var currentLocation: CLLocation? = CLLocation(latitude: 31.2653, longitude: 32.3019) // Port Said
    var authorizationStatus: CLAuthorizationStatus = .authorizedWhenInUse
    func requestLocation() {}
}
#endif
