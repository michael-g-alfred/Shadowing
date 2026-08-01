import SwiftUI

struct TaskCardSkeleton: View {
    
        // MARK: - State
    @State private var shimmer = false
    
        // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            
            VStack(alignment: .leading, spacing: 12) {
                
                
                VStack(alignment: .leading, spacing: 13) {
                    
                    VStack(alignment: .leading, spacing: 14) {
                        
                            // MARK: 1. Header (AvatarView + Badges)
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            
                            HStack(alignment: .top, spacing: Spacing.sm) {
                                
                                    // Avatar & Info Skeleton
                                HStack(spacing: Spacing.sm) {
                                    Circle()
                                        .fill(shimmerColor)
                                        .frame(width: 44, height: 44)
                                    
                                    VStack(alignment: .leading, spacing: Spacing.sm) {
                                        RoundedRectangle(cornerRadius: CornerRadius.xs)
                                            .fill(shimmerColor)
                                            .frame(width: 120, height: 14)
                                        
                                        RoundedRectangle(cornerRadius: CornerRadius.xs)
                                            .fill(shimmerColor)
                                            .frame(width: 75, height: 10)
                                    }
                                }
                                
                                Spacer(minLength: Spacing.xl)
                                
                                    // Budget & Service Badges Skeleton
                                VStack(alignment: .trailing, spacing: Spacing.sm) {
                                    Capsule()
                                        .fill(shimmerColor)
                                        .frame(width: 85, height: 22)
                                    
                                    RoundedRectangle(cornerRadius: CornerRadius.xs)
                                        .fill(shimmerColor)
                                        .frame(width: 95, height: 12)
                                }
                            }
                        }
                        
                            // MARK: 2. Content (Title + Description)
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            RoundedRectangle(cornerRadius: CornerRadius.xs)
                                .fill(shimmerColor)
                                .frame(width: 180, height: 20)
                            
                            RoundedRectangle(cornerRadius: CornerRadius.xs)
                                .fill(shimmerColor)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .frame(height: 14)
                        }
                    }
                    
                    Divider()
                }
                
                    // MARK: 3. Location Row
                HStack(alignment: .center, spacing: Spacing.sm) {
                    Capsule()
                        .fill(shimmerColor)
                        .frame(width: 70, height: 24)
                    
                    RoundedRectangle(cornerRadius: CornerRadius.xs)
                        .fill(shimmerColor)
                        .frame(width: 150, height: 12)
                }
                
                    // MARK: 4. Badges Row
                HStack(spacing: Spacing.xs) {
                    Capsule()
                        .fill(shimmerColor)
                        .frame(width: 60, height: 23)
                    
                    Capsule()
                        .fill(shimmerColor)
                        .frame(width: 73, height: 23)
                    
                    Capsule()
                        .fill(shimmerColor)
                        .frame(width: 40, height: 23)
                    
                    Spacer()
                }
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
                .strokeBorder(Color.gray.opacity(0.15), lineWidth: 1)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                shimmer = true
            }
        }
    }
    
        // MARK: - Private Properties
    private var shimmerColor: Color {
        Color.gray.opacity(shimmer ? 0.25 : 0.12)
    }
}

    // MARK: - Preview

#Preview {
    TaskCardSkeleton()
}

struct TaskCardSingletonList: View {
    
        // MARK: - Properties
    let count: Int
    
        // MARK: - Init
    init(count: Int = 5) {
        self.count = count
    }
    
        // MARK: - Body
    var body: some View {
        VStack(spacing: Spacing.lg) {
            ForEach(0..<count, id: \.self) { _ in
                TaskCardSkeleton()
            }
        }
        .padding(.vertical, Spacing.sm)
        .padding(.horizontal)
    }
}
