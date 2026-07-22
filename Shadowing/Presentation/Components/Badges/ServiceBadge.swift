import SwiftUI
import CoreLocation

struct ServiceBadge: View {
    let task: TaskModel
    
    var body: some View {
        HStack(alignment: .center, spacing: 2) {
            Image(systemName: task.serviceType.icon)
            Text(task.serviceType.localizedLabel)
        }
        .font(.caption).fontWeight(.bold).foregroundStyle(.tertiary)
    }
}
