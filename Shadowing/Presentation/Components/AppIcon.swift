import SwiftUI

struct AppIcon: View {
    let icon: String
    var size: CGFloat = 100
    var iconSize: CGFloat = 53
    var color: Color = .accentColor
    
    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.15))
                .frame(width: size, height: size)
            
            Circle()
                .strokeBorder(color.opacity(0.5), lineWidth: 2)
                .frame(width: size, height: size)
            
            Image(systemName: icon)
                .font(.system(size: iconSize))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(color)
                .symbolEffect(.bounce, options: .repeat(1), value: icon)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        AppIcon(icon: "star.fill")
        AppIcon(icon: "checkmark.circle.fill", size: 60, iconSize: 20, color: .green)
    }
}
