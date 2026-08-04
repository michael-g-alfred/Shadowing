import SwiftUI

struct SetupOptionCard: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                
                Image(systemName: icon)
                    .imageScale(.large)
                    .foregroundStyle(isSelected ? .accent : .secondary)
                
                Text(title)
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                
                Image(systemName: isSelected ? "checkmark.circle" : "circle")
                    .imageScale(.large)
                    .foregroundStyle(isSelected ? Color(.accent): .secondary)
            }
            .padding(Spacing.md)
            .appGlassCapsule()
        }
        .buttonStyle(.plain)
    }
}
