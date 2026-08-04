import SwiftUI

struct ServiceBadge: View {
    let service: TaskServiceLookup
    @Environment(\.locale) private var locale

    var body: some View {
        HStack(alignment: .center, spacing: 2) {
            Image(systemName: service.icon)
            Text(service.label)
        }
        .font(.caption).fontWeight(.bold).foregroundStyle(.tertiary)
    }
}
