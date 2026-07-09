import SwiftUI
import CoreLocation

struct BudgetBadge: View {
    let task: TaskModel
    
    var body: some View {
        Text(task.budget.formatted(.currency(code: task.currency)))
            .font(.caption2).fontWeight(.bold).foregroundStyle(task.priority.color)
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background { Capsule().fill(task.priority.color.opacity(0.1)) }
            .overlay { Capsule().strokeBorder(task.priority.color.opacity(0.25), lineWidth: 1) }
    }
}
