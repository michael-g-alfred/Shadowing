import SwiftUI

struct StatusBadge: View {
    let status: StatusLookup
    @Environment(\.locale) private var locale

    private var color: Color { Color(lookupName: status.color) }

    var body: some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 5, height: 5)
                .shadow(color: color.opacity(0.3), radius: 2)
            Text(status.label)
                .font(.caption2).fontWeight(.bold).textCase(.uppercase).foregroundStyle(color)
        }
        .padding(.horizontal, 6).padding(.vertical, 4)
        .appGlassCapsule(
            overlayColor: color.opacity(0.1),
            strokeColor: color.opacity(0.05),
            shadowColor: color.opacity(0.05)
        )
    }
}
