import SwiftUI

struct SetupHeaderView: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.12))
                    .frame(width: 100, height: 100)
                
                Circle()
                    .strokeBorder(Color.accentColor.opacity(0.25), lineWidth: 1)
                    .frame(width: 100, height: 100)
                
                Image(systemName: icon)
                    .font(.system(size: 34, weight: .medium))
                    .foregroundStyle(.accent)
                    .symbolEffect(.bounce, options: .repeat(1), value: icon)
            }
            
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
