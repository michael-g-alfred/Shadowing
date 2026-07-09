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
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background { Capsule().fill(status.color.opacity(0.1)) }
        .overlay { Capsule().strokeBorder(status.color.opacity(0.25), lineWidth: 1) }
    }
}
