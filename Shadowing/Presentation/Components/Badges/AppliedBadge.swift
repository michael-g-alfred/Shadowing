import SwiftUI

struct AppliedBadge: View {
    
        // MARK: - Environment
    @Environment(\.colorScheme) private var colorScheme
    
        // MARK: - Properties
    var darkMode: Bool { colorScheme == .dark }
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(darkMode ? .white : .green)
                .frame(width: 5, height: 5)
            
            Text("Applied")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(darkMode ? .white : .green)
                .fixedSize(horizontal: true, vertical: false)
        }
        .padding(.horizontal, 6).padding(.vertical, 4)
        .appGlassCapsule(
            overlayColor: darkMode ? .green.opacity(0.1) : .green.opacity(0.2),
            strokeColor: darkMode ? .green.opacity(0.05) : .green,
        )
    }
}
