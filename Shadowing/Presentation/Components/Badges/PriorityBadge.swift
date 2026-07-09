import SwiftUI
import CoreLocation

struct PriorityBadge: View {
    let priority: TaskPriority
    
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: priority.icon)
                .font(.caption2).fontWeight(.bold).foregroundStyle(priority.color)
            Text(priority.localizedLabel)
                .font(.caption2).fontWeight(.bold).textCase(.uppercase).foregroundStyle(priority.color)
        }
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background { Capsule().fill(priority.color.opacity(0.1)) }
        .overlay { Capsule().strokeBorder(priority.color.opacity(0.25), lineWidth: 1) }
    }
}
