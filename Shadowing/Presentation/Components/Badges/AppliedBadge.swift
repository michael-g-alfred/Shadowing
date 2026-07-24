import SwiftUI

struct AppliedBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(.white)
                .frame(width: 5, height: 5)
            
            Text("Applied")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 6).padding(.vertical, 4)
        .GlassCapsule(
            overlayColor: .green.opacity(0.1),
            strokeColor: .green.opacity(0.05),
            shadowColor: .green.opacity(0.05)
        )
    }
}
