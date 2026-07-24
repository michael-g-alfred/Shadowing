import SwiftUI

struct ApplicantsBadge: View {
    
    let applicants: Int
    let color:      Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "person.2.fill").font(.caption2)
            Text("\(applicants)")
                .font(.caption2)
                .fontWeight(.bold)
                .contentTransition(.numericText())
        }
        .foregroundStyle(color)
        .padding(.horizontal, 6).padding(.vertical, 4)
        .background { Capsule().fill(color.opacity(0.1)) }
        .GlassCapsule(
            overlayColor: color.opacity(0.1),
            strokeColor: color.opacity(0.05),
            shadowColor: color.opacity(0.05)
        )
    }
}
