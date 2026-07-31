import SwiftUI

struct TaskCardSingleton: View {
    
        // MARK: - State
    @State private var shimmer = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            
                // MARK: Header (mirrors AvatarView + BudgetBadge/ServiceBadge)
            HStack(alignment: .center, spacing: Spacing.md) {
                
                HStack(spacing: Spacing.sm) {
                    Circle()
                        .fill(shimmerColor)
                        .frame(width: 44, height: 44)
                    
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        RoundedRectangle(cornerRadius: CornerRadius.xs)
                            .fill(shimmerColor)
                            .frame(width: 90, height: 12)
                        RoundedRectangle(cornerRadius: CornerRadius.xs)
                            .fill(shimmerColor)
                            .frame(width: 60, height: 10)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .center, spacing: Spacing.xs) {
                    Capsule()
                        .fill(shimmerColor)
                        .frame(width: 60, height: 20)
                    Capsule()
                        .fill(shimmerColor)
                        .frame(width: 70, height: 14)
                }
            }
            .frame(maxHeight: 44)
            
                // MARK: Content (mirrors title + description)
            VStack(alignment: .leading, spacing: Spacing.xs) {
                RoundedRectangle(cornerRadius: CornerRadius.xs)
                    .fill(shimmerColor)
                    .frame(width: 180, height: 16)
                
                RoundedRectangle(cornerRadius: CornerRadius.xs)
                    .fill(shimmerColor)
                    .frame(maxWidth: .infinity, maxHeight: 12)
                
                RoundedRectangle(cornerRadius: CornerRadius.xs)
                    .fill(shimmerColor)
                    .frame(width: 140, height: 12)
            }
            
            Divider()
            
                // MARK: Footer (mirrors DistanceBadge + LocationBadge)
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack(alignment: .center, spacing: Spacing.sm) {
                    Capsule()
                        .fill(shimmerColor)
                        .frame(width: 55, height: 20)
                }
                
                HStack(spacing: Spacing.xs) {
                    RoundedRectangle(cornerRadius: CornerRadius.xs)
                        .fill(shimmerColor)
                        .frame(width: 14, height: 14)
                    RoundedRectangle(cornerRadius: CornerRadius.xs)
                        .fill(shimmerColor)
                        .frame(width: 130, height: 12)
                }
            }
            
                // MARK: Bottom row (mirrors PriorityBadge + StatusBadge + ApplicantsBadge)
            HStack(spacing: Spacing.xs) {
                Capsule()
                    .fill(shimmerColor)
                    .frame(width: 65, height: 20)
                Capsule()
                    .fill(shimmerColor)
                    .frame(width: 60, height: 20)
                Capsule()
                    .fill(shimmerColor)
                    .frame(width: 40, height: 20)
                Spacer()
            }
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous)
                .fill(.thinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous)
                        .fill(Color.gray.opacity(0.05))
                )
        )
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous)
                .strokeBorder(Color.gray.opacity(0.15), lineWidth: 1.5)
        }
        .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 4)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                shimmer = true
            }
        }
        .redacted(reason: .placeholder)
    }
    
        // MARK: - Helpers
    private var shimmerColor: Color {
        Color.gray.opacity(shimmer ? 0.25 : 0.15)
    }
}

    // MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: Spacing.lg) {
            TaskCardSingleton()
            TaskCardSingleton()
            TaskCardSingleton()
        }
        .padding()
    }
}

    // MARK: - Convenience list of skeletons (drop-in replacement while loading)

struct TaskCardSingletonList: View {
    let count: Int
    
    init(count: Int = 5) {
        self.count = count
    }
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            ForEach(0..<count, id: \.self) { _ in
                TaskCardSingleton()
            }
        }
        .padding(.vertical, Spacing.sm)
        .padding(.horizontal)
    }
}
