import SwiftUI

struct ChatView: View {
    
    @State private var vm: ChatViewModel
    
    init(taskId: String, vm: ChatViewModel) {
        _vm = State(initialValue: vm)
    }
    
    var body: some View {
        content
            .task { await vm.loadConversations() }
            .navigationTitle("\(vm.)'s Chat")
            .navigationBarTitleDisplayMode(.inline)
    }
    
    @ViewBuilder
    private var content: some View {
        if vm.isLoading {
            LoadingState.loading(title: "Loading", subtitle: "Fetching task details").view
        } else if let error = vm.errorMessage {
            LoadingState.error(message: error).view
        } else if let conversations = vm.conversations {
            List {
            }
            .listStyle(.insetGrouped)
        }
    }
}


#Preview {
    ChatView()
}
