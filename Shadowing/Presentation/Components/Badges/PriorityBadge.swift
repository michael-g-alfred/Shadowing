import SwiftUI

struct PriorityBadge: View {
    
        // MARK: - Environment
    @Environment(\.colorScheme) private var colorScheme

        // MARK: - Properties
    var darkMode: Bool { colorScheme == .dark }
    let priority: PriorityLookup
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
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .appGlassCapsule(
            overlayColor: darkMode ? color.opacity(0.1) : color.opacity(0.2),
            strokeColor: darkMode ? color.opacity(0.1) : color,
        )
    }
}
