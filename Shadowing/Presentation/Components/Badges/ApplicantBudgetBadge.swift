import SwiftUI

struct ApplicantBudgetBadge: View {
    let taskBudget: Double
    let proposedBudget: Double?

    private var budgetInfo: (text: String, icon: String, color: Color) {
        guard let proposedBudget else {
            return (taskBudget.formatted(.currency(code: "EGP")), "equal.circle", .gray)
        }

        if proposedBudget > taskBudget {
            return (proposedBudget.formatted(.currency(code: "EGP")), "arrow.up.circle", .red)
        } else if proposedBudget < taskBudget {
            return (proposedBudget.formatted(.currency(code: "EGP")), "arrow.down.circle", .green)
        } else {
            return (proposedBudget.formatted(.currency(code: "EGP")), "equal.circle", .gray)
        }
    }

    var body: some View {
        let info = budgetInfo

        Label(info.text, systemImage: info.icon)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(info.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .appGlassCapsule(
                overlayColor: info.color.opacity(0.1),
                strokeColor: info.color.opacity(0.05),
                shadowColor: info.color.opacity(0.05)
            )
    }
}
