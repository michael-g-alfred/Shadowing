import SwiftUI

struct SetupHeaderView: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            
            AppIcon(icon: icon)
            
            VStack(spacing: Spacing.xs) {
                Text(title)
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .multilineTextAlignment(.center)
                
                if let subtitle {
                    Text(subtitle)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }
}
