import SwiftUI

struct PriorityBadge: View {
    let priority: PriorityLookup
    @Environment(\.locale) private var locale

    private var color: Color { Color(lookupName: priority.color) }

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: priority.icon)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(color)

            Text(priority.label)
                .font(.caption2)
                .fontWeight(.bold)
                .textCase(.uppercase)
                .foregroundStyle(color)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .appGlassCapsule(
            overlayColor: color.opacity(0.1),
            strokeColor: color.opacity(0.05),
            shadowColor: color.opacity(0.05)
        )
    }
}
