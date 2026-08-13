import SwiftUI

struct SpecialtyBadge: View {
    
        // MARK: - Properties
    let specialty: SpecialtyModel
    
    var body: some View {
        HStack(alignment: .center, spacing: Spacing.xs) {
            Image(systemName: specialty.icon)
            Text(specialty.label)
                .fixedSize(horizontal: true, vertical: false)
            
        }
        .font(.caption).fontWeight(.bold).foregroundStyle(.primary)
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .appGlassCapsule(
            overlayColor: .green.opacity(0.25),
            strokeColor: .green.opacity(0.05)
        )
    }
}
