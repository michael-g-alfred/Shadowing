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
                    .contentTransition(.opacity)
                    .id(title) // forces the transition to re-trigger on each greeting change
                
                if let subtitle {
                    Text(subtitle)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .contentTransition(.opacity)
                        .id(subtitle)
                }
            }
        }
    }
}
