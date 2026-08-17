import SwiftUI
import CoreLocation

struct BudgetBadge: View {
    
        // MARK: - Environment
    @Environment(DIContainer.self) private var container
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.locale) private var locale
    
        // MARK: - Properties
    var darkMode: Bool { colorScheme == .dark }
    let task: TaskModel
    
        // MARK: - Lookup-resolved value
    private var priorityColor: Color {
        let colorName = container.lookupStore.priority(named: task.priority)?.color ?? "gray"
        return Color(lookupName: colorName)
    }
    
        // MARK: - Body
    var body: some View {
        Text(
            task.budget.formatted(
                .currency(code: task.currency)
                .locale(locale)
                .precision(.fractionLength(0))
            )
        )
        .font(.caption2).fontWeight(.bold).foregroundStyle(priorityColor)
        .padding(.horizontal, 6).padding(.vertical, 4)
        .fixedSize(horizontal: true, vertical: false)
        .appGlassCapsule(
            overlayColor: darkMode ? priorityColor.opacity(0.1) : priorityColor.opacity(0.2),
            strokeColor: darkMode ? priorityColor.opacity(0.05) : priorityColor,
        )
    }
}
