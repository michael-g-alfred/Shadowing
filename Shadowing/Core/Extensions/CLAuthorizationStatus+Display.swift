import CoreLocation
import SwiftUI

extension CLAuthorizationStatus {
    var displayTitle: String {
        switch self {
            case .authorizedAlways: return "Always Allowed"
            case .authorizedWhenInUse: return "Allowed While Using App"
            case .denied: return "Denied"
            case .restricted: return "Restricted"
            case .notDetermined: return "Not Determined"
            @unknown default: return "Unknown"
        }
    }
    
    var iconName: String {
        switch self {
            case .authorizedAlways, .authorizedWhenInUse: return "location.fill"
            case .denied, .restricted: return "location.slash"
            case .notDetermined: return "location"
            @unknown default: return "location"
        }
    }
    
    var tintColor: Color {
        switch self {
            case .authorizedAlways, .authorizedWhenInUse: return .green
            case .denied, .restricted: return .red
            case .notDetermined: return .orange
            @unknown default: return .gray
        }
    }
}
