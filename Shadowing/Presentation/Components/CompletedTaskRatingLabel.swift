import SwiftUI

struct CompletedTaskRatingLabel: View {
    let rating:         Double
    let completedTasks: Int

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            HStack(spacing: 4) {
                Text("Completed Tasks:").font(.caption).foregroundStyle(.secondary)
                Text("\(completedTasks)").font(.caption).foregroundStyle(.primary).fontWeight(.semibold)
            }
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                Text(String(format: "%.1f", rating))
            }
            .font(.caption).bold().foregroundStyle(.rating)
        }
    }
}
