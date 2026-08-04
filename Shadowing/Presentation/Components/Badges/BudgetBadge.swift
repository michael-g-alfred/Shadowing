import SwiftUI
import CoreLocation

struct BudgetBadge: View {
    
        // MARK: - Environment
    @Environment(DIContainer.self) private var container
    
        // MARK: - Properties
    let task: TaskModel
    
        // MARK: - Lookup-resolved value
    private var priorityColor: Color {
        let colorName = container.lookupStore.priority(named: task.priority)?.color ?? "gray"
        return Color(lookupName: colorName)
    }
    
        // MARK: - Body
    var body: some View {
        Text(task.budget.formatted(.currency(code: task.currency)))
            .font(.caption2).fontWeight(.bold).foregroundStyle(priorityColor)
            .padding(.horizontal, 6).padding(.vertical, 4)
            .appGlassCapsule(
                overlayColor: priorityColor.opacity(0.1),
                strokeColor: priorityColor.opacity(0.05),
                shadowColor: priorityColor.opacity(0.05)
            )
    }
}
