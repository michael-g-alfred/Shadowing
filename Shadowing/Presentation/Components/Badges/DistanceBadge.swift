import SwiftUI
import CoreLocation

struct DistanceBadge: View {
    let taskLocation: CLLocation
    @Environment(DIContainer.self) private var container
    
    private var distanceInKm: Double? {
        guard let currentLocation = container.locationService.currentLocation else { return nil }
        return currentLocation.distance(from: taskLocation) / 1000.0
    }
    
    var body: some View {
        if let distanceInKm {
            HStack(spacing: 3) {
                Image(systemName: "location.fill")
                    .font(.caption2)
                Text("\(distanceInKm, specifier: "%.0f") km")
                    .font(.caption2)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.cyan)
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .appGlassCapsule(
                overlayColor: .cyan.opacity(0.1),
                strokeColor: .cyan.opacity(0.05),
                shadowColor: .cyan.opacity(0.05)
            )
        }
    }
}
