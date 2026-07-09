import SwiftUI

struct LocationBadge: View {
    let task: TaskModel

    var body: some View {
        HStack(alignment: .center, spacing: 3) {
            Image(systemName: "map.fill")
            Text(task.address)
        }
        .font(.caption).fontWeight(.medium).foregroundStyle(.secondary)
    }
}
