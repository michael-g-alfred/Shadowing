import SwiftUI

struct TimeOfDaySelectionView: View {
    let availableTimesOfDay: [TimeOfDayLookup]
    @Binding var selection: TimeOfDayLookup?
    
    private let columns = [
        GridItem(.flexible(), spacing: Spacing.md),
        GridItem(.flexible(), spacing: Spacing.md)
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: Spacing.md) {
            ForEach(availableTimesOfDay) { time in
                TimeOfDayCard(
                    time: time,
                    isSelected: selection == time
                ) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        selection = time
                    }
                }
            }
        }
        .padding(Spacing.md)
        .sensoryFeedback(.selection, trigger: selection)
    }
}

    // MARK: - TimeOfDayCard
private struct TimeOfDayCard: View {
    let time: TimeOfDayLookup
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack(alignment: .top) {
                    AppIcon(
                        icon: time.icon,
                        size: 44,
                        iconSize: 20,
                        color: isSelected ? .white : .accent
                    )
                    
                    Spacer()
                    
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(isSelected ? .white : .secondary.opacity(0.5))
                        .contentTransition(.symbolEffect)
                }
                
                Spacer(minLength: Spacing.xs)
                
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(time.label)
                        .font(.headline)
                        .foregroundStyle(isSelected ? .white : .primary)
                    
                    Text(time.subTitle)
                        .font(.caption)
                        .foregroundStyle(isSelected ? .white.opacity(0.85) : .secondary)
                        .lineLimit(1)
                }
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
            .appGlassCard(isSelected: isSelected)
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .contentShape(RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

    // MARK: - Updated Glass Card Modifier
struct AppGlassCard: ViewModifier {
    let isSelected: Bool
    var cornerRadius: CGFloat = CornerRadius.xl
    
    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        
        content
            .background(
                ZStack {
                    if isSelected {
                        shape.fill(Color.accentColor)
                    } else {
                        shape.fill(.thinMaterial)
                        shape.fill(Color.accentColor.opacity(0.05))
                    }
                }
            )
            .clipShape(shape)
            .overlay(
                shape.strokeBorder(
                    isSelected ? Color.white.opacity(0.3) : Color(.separator),
                    lineWidth: isSelected ? 2 : 1
                )
            )
            .shadow(
                color: isSelected ? Color.accentColor.opacity(0.12) : Color.black.opacity(0.03),
                radius: isSelected ? 1 : 0,
                x: 0,
                y: isSelected ? 1 : 0
            )
    }
}

extension View {
    func appGlassCard(isSelected: Bool = false, cornerRadius: CGFloat = CornerRadius.xl) -> some View {
        modifier(AppGlassCard(isSelected: isSelected, cornerRadius: cornerRadius))
    }
}
