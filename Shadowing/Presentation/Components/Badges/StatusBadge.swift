import SwiftUI

struct StatusBadge: View {
    
        // MARK: - Environment
    @Environment(\.colorScheme) private var colorScheme

        // MARK: - Properties
    var darkMode: Bool { colorScheme == .dark }
    let status: StatusLookup
    private var color: Color { Color(lookupName: status.color) }

    var body: some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 5, height: 5)
                .shadow(color: color.opacity(0.3), radius: 2)
            Text(status.label)
                .font(.caption2).fontWeight(.bold).textCase(.uppercase).foregroundStyle(color)
                .fixedSize(horizontal: true, vertical: false)
        }
        .padding(.horizontal, 6).padding(.vertical, 4)
        .appGlassCapsule(
            overlayColor: darkMode ? color.opacity(0.1) : color.opacity(0.2),
            strokeColor: darkMode ? color.opacity(0.05) : color,
            shadowColor: darkMode ? color.opacity(0.05) : color.opacity(0.1)
        )
    }
}
