import SwiftUI

struct ChatView: View {
    var body: some View {
        LoadingState.loading(title: "No chat messages", subtitle: "Try again later").view
        InfoRow(title: "Test title", systemImage: "clock.badge", localizedValue: "Value text", iconColor: .brown, valueColor: .brown)
    }
}

#Preview {
    ChatView()
}
