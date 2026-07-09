import SwiftUI
import CoreLocation

// MARK: - DistanceBadge

struct DistanceBadge: View {
    let taskLocation: CLLocation
    @Environment(DIContainer.self) private var container

    private var distance: String? {
        container.locationService.currentLocation?.distance(from: taskLocation).formatted(.number)
    }

    var body: some View {
        if let distance {
            HStack(spacing: 3) {
                Image(systemName: "location.fill").font(.caption2)
                Text(distance).font(.caption2).fontWeight(.semibold)
            }
            .foregroundStyle(.cyan)
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background { Capsule().fill(Color.cyan.opacity(0.1)) }
            .overlay { Capsule().strokeBorder(Color.cyan.opacity(0.25), lineWidth: 1) }
        }
    }
}
