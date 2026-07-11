import SwiftUI

struct ChatView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                TaskCardSingletonList(count: 4)
            }
        }
        .navigationTitle("Chat")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ChatView()
}
