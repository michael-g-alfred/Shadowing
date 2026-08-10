import SwiftUI

struct LocationBadge: View {
    
        // MARK: - Properties
    let task: TaskModel
    
    var body: some View {
        HStack(alignment: .center, spacing: 3) {
            Image(systemName: "map.fill")
            Text(task.address)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
        .font(.caption).fontWeight(.medium).foregroundStyle(.secondary)
    }
}
