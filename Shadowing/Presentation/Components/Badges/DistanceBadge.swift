import SwiftUI
import CoreLocation

struct DistanceBadge: View {
    
        // MARK: - Environment
    @Environment(DIContainer.self) private var container
    @Environment(\.colorScheme) private var colorScheme
    
        // MARK: - Properties
    var darkMode: Bool { colorScheme == .dark }
    let taskLocation: CLLocation
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
                    .fixedSize(horizontal: true, vertical: false)
            }
            .foregroundStyle(.cyan)
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .appGlassCapsule(
                overlayColor: darkMode ? .cyan.opacity(0.1) : .cyan.opacity(0.2),
                strokeColor: darkMode ? .cyan.opacity(0.05) : .cyan,
                shadowColor: darkMode ? .cyan.opacity(0.05) : .cyan.opacity(0.1)
            )
        }
    }
}
