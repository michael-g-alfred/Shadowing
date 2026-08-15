import SwiftUI
import CoreLocation

struct RequireLocationModifier: ViewModifier {
    let locationService: LocationServiceProtocol
    
    func body(content: Content) -> some View {
        Group {
            switch locationService.authorizationStatus {
                case .authorizedWhenInUse, .authorizedAlways:
                    content
                    
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
    func requireLocation(_ locationService: LocationServiceProtocol) -> some View {
        modifier(RequireLocationModifier(locationService: locationService))
    }
}
