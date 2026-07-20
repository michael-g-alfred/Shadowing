import SwiftUI
import CoreLocation

@MainActor
@Observable
final class SettingsViewModel {
    
    private let locationService: LocationService
    private let languageManager: LanguageManager
    
    init(locationService: LocationService, languageManager: LanguageManager) {
        self.locationService = locationService
        self.languageManager = languageManager
    }
    
        // MARK: - Location
    
    var locationAuthorizationStatus: CLAuthorizationStatus {
        locationService.authorizationStatus
    }
    
    var locationStatusTitle: String {
        switch locationAuthorizationStatus {
            case .authorizedAlways: return "Always Allowed"
            case .authorizedWhenInUse: return "Allowed While Using App"
            case .denied: return "Denied"
            case .restricted: return "Restricted"
            case .notDetermined: return "Not Determined"
            @unknown default: return "Unknown"
        }
    }
    
    var locationStatusIcon: String {
        switch locationAuthorizationStatus {
            case .authorizedAlways, .authorizedWhenInUse: return "location.fill"
            case .denied, .restricted: return "location.slash"
            case .notDetermined: return "location"
            @unknown default: return "location"
        }
    }
    
    var locationStatusTint: Color {
        switch locationAuthorizationStatus {
            case .authorizedAlways, .authorizedWhenInUse: return .green
            case .denied, .restricted: return .red
            case .notDetermined: return .orange
            @unknown default: return .gray
        }
    }
    
    var needsLocationSettingsRedirect: Bool {
        locationAuthorizationStatus == .denied || locationAuthorizationStatus == .restricted
    }
    
    var needsLocationRequest: Bool {
        locationAuthorizationStatus == .notDetermined
    }
    
    func requestLocationAccess() {
        locationService.requestLocation()
    }
    
        // MARK: - Language
    
    var currentLanguage: AppLanguage {
        languageManager.currentLanguage
    }
    
    func setLanguage(_ language: AppLanguage) {
        languageManager.setLanguage(language)
    }
}
