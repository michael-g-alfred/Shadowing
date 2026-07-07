import SwiftUI

struct ChatView: View {
    var body: some View {
        LoadingState.loading(title: "No chat messages", subtitle: "Try again later").view
    }
}

#Preview {
    ChatView()
}
