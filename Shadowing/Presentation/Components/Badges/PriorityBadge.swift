import SwiftUI
import CoreLocation

struct PriorityBadge: View {
    let priority: TaskPriority
    
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: priority.icon)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(priority.color)
            
            Text(priority.localizedLabel)
                .font(.caption2)
                .fontWeight(.bold)
                .textCase(.uppercase)
                .foregroundStyle(priority.color)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .GlassCapsule(
            overlayColor: priority.color.opacity(0.1),
            strokeColor: priority.color.opacity(0.05),
            shadowColor: priority.color.opacity(0.05)
        )
    }
}
