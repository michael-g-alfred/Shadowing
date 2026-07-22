import SwiftUI
import CoreLocation

struct BudgetBadge: View {
    let task: TaskModel
    
    var body: some View {
        Text(task.budget.formatted(.currency(code: task.currency)))
            .font(.caption2).fontWeight(.bold).foregroundStyle(task.priority.color)
            .padding(.horizontal, 10).padding(.vertical, 5)
            .GlassCapsule(
                overlayColor: task.priority.color.opacity(0.1),
                strokeColor: task.priority.color.opacity(0.05),
                shadowColor: task.priority.color.opacity(0.05)
            )    }
}
