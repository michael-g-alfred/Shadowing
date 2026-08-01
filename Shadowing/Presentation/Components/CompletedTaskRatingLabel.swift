import SwiftUI

struct CompletedTaskRatingLabel: View {
    let rating:         Double
    let completedTasks: Int
    
    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "star.fill")
            Text(String(format: "%.1f", rating))
        }
        .font(.caption).bold().foregroundStyle(.rating)
    }
}

