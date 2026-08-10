import SwiftUI

struct ApplicantsBadge: View {
    
        // MARK: - Environment
    @Environment(\.colorScheme) private var colorScheme
    
        // MARK: - Properties
    var darkMode: Bool { colorScheme == .dark }
    let applicants: Int
    let color:      Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "person.2.fill").font(.caption2)
            Text("\(applicants)")
                .font(.caption2)
                .fontWeight(.bold)
                .fixedSize(horizontal: true, vertical: false)
                .contentTransition(.numericText())
        }
        .foregroundStyle(color)
        .padding(.horizontal, 6).padding(.vertical, 4)
        .background { Capsule().fill(color.opacity(0.1)) }
        .appGlassCapsule(
            overlayColor: darkMode ? color.opacity(0.1) : color.opacity(0.2),
            strokeColor: darkMode ? color.opacity(0.05) : color,
            shadowColor: darkMode ? color.opacity(0.05) : color.opacity(0.1)
        )
    }
}
