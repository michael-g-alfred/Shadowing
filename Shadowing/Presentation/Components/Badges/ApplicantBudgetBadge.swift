import SwiftUI

struct ApplicantBudgetBadge: View {
    
        // MARK: - Environment
    @Environment(\.colorScheme) private var colorScheme

        // MARK: - Properties
    var darkMode: Bool { colorScheme == .dark }
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
            .fixedSize(horizontal: true, vertical: false)
            .foregroundStyle(info.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .appGlassCapsule(
                overlayColor: darkMode ? info.color.opacity(0.1) : info.color.opacity(0.2),
                strokeColor: darkMode ? info.color.opacity(0.05) : info.color,
                shadowColor: darkMode ? info.color.opacity(0.05) : info.color.opacity(0.1)
            )
    }
}
