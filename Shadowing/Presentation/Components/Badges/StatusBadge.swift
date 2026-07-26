import SwiftUI

struct StatusBadge: View {
    let status: TaskStatus
    
    var body: some View {
        HStack(spacing: 4) {
            Circle().fill(status.color).frame(width: 5, height: 5)
                .shadow(color: status.color.opacity(0.3), radius: 2)
            Text(status.localizedLabel)
                .font(.caption2).fontWeight(.bold).textCase(.uppercase).foregroundStyle(status.color)
        }
        .padding(.horizontal, 6).padding(.vertical, 4)
        .appGlassCapsule(
            overlayColor: status.color.opacity(0.1),
            strokeColor: status.color.opacity(0.05),
            shadowColor: status.color.opacity(0.05)
        )
    }
}
