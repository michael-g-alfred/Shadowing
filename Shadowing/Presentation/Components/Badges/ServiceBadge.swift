import SwiftUI

struct ServiceBadge: View {
    
        // MARK: - Properties
    let service: TaskServiceLookup
    
    var body: some View {
        HStack(alignment: .center, spacing: Spacing.xs) {
            Image(systemName: service.icon)
            Text(service.label)
                .fixedSize(horizontal: true, vertical: false)
            
        }
        .font(.caption).fontWeight(.bold).foregroundStyle(.secondary)
    }
}
