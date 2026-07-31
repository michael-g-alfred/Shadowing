import SwiftUI
import CoreLocation

struct RequireLocationModifier: ViewModifier {
    let locationService: LocationService
    
    func body(content: Content) -> some View {
        Group {
            switch locationService.authorizationStatus {
                case .authorizedWhenInUse, .authorizedAlways:
                    content
                    
                case .notDetermined:
                    ProgressView()
                        .task {
                            locationService.requestLocation()
                        }
                    
                default:
                    EmptyState.noLocationAccess.view(settingsAction:  {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    })
            }
        }
    }
}

extension View {
    func requireLocation(_ locationService: LocationService) -> some View {
        modifier(RequireLocationModifier(locationService: locationService))
    }
}
