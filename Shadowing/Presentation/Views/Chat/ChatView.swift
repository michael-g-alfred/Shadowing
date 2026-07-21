import SwiftUI

    // MARK: - DirectChatLoaderView
struct DirectChatLoaderView: View {
    let taskId: String
    @Bindable var vm: ChatViewModel
    
    var body: some View {
        Group {
            if let conversation = vm.conversations.first(where: { $0.id == taskId }) {
                ConversationDetailView(conversation: conversation, vm: vm)
            } else {
                LoadingState.loading(title: "Loading chat", subtitle: "Please wait while we load your chat.").view
                    .task {
                        vm.listenToConversations()
                    }
            }
        }
    }
}

    // MARK: - Message Status View Component
struct MessageStatusView: View {
    let status: MessageStatus
    
    var body: some View {
        Image(systemName: status.iconName)
            .font(.caption)
            .foregroundColor(status.iconColor)
    }
}

    // MARK: - Conversation Row View
struct ConversationRow: View {
    let conversation: Conversation
    
    var body: some View {
        HStack(alignment: .top) {
            AvatarView(
                profile: conversation.otherUser,
                nameLayout: .horizontal,
                subtitle: conversation.lastMessage
            )
            
            Spacer(minLength: 12)
            
            VStack(alignment: .trailing) {
                Text(conversation.lastMessageTime)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Spacer()
                
                MessageStatusView(status: conversation.lastMessageStatus)
            }
        }
    }
}

    // MARK: - Message Bubble View
struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if !message.isCurrentUser {
                AvatarView(profile: message.sender, size: 32, nameLayout: .none)
            } else {
                Spacer()
            }
            
            VStack(alignment: message.isCurrentUser ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(message.isCurrentUser ? Color.blue.opacity(0.75) : Color.blue.opacity(0.25))
                    .foregroundColor(message.isCurrentUser ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                
                HStack(spacing: 4) {
                    Text(message.time)
                        .font(.caption2)
                        .foregroundColor(.gray)
                    
                    if message.isCurrentUser, let status = message.status {
                        MessageStatusView(status: status)
                    }
                }
                .padding(.horizontal, 4)
            }
            
            if message.isCurrentUser {
                AvatarView(profile: message.sender, size: 32, nameLayout: .none)
            } else {
                Spacer()
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
}

    // MARK: - Main Chat List View
struct ChatView: View {
    
        // MARK: - Environment
    @Environment(\.colorScheme) private var colorScheme
    
        // MARK: - Properties
    var vm: ChatViewModel
    
    private var listRowColor: Color? {
        colorScheme == .dark
        ? Color.accentColor.opacity(0.15)
        : nil
    }
    
        // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                
                contentView
            }
            .navigationTitle("Chats")
            .task {
                vm.listenToConversations()
            }
        }
    }
    
        // MARK: - Content View
    @ViewBuilder
    private var contentView: some View {
        if vm.isLoading && vm.conversations.isEmpty {
            LoadingState.loading(title: "Loading chats...", subtitle: "Please wait a moment.").view
        } else if vm.conversations.isEmpty {
            EmptyState.noChats.view()
        } else {
            conversationList
        }
    }
    
        // MARK: - Conversation List Component
    private var conversationList: some View {
        List(vm.conversations) { conversation in
            NavigationLink(destination: ConversationDetailView(conversation: conversation, vm: vm)) {
                ConversationRow(conversation: conversation)
            }
            .listRowBackground(listRowColor)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .refreshable {
            vm.listenToConversations()
        }
    }
}

    // MARK: - Conversation Detail View
struct ConversationDetailView: View {
    
        // MARK: - Environment
    @Environment(\.colorScheme) private var colorScheme
    
        // MARK: - Properties
    private var backgroundColor: Color? {
        colorScheme == .dark
        ? .accentColor.opacity(0.15)
        : .gray.opacity(0.15)
    }
    let conversation: Conversation
    
        // MARK: - State
    @Bindable var vm: ChatViewModel
    @State private var messageText: String = ""
    
        // MARK: - Body
    var body: some View {
        ZStack {
            AppBackground()
            
            VStack(alignment: .leading, spacing: 0) {
                AvatarView(profile: conversation.otherUser, size: 48, nameLayout: .horizontal, subtitle: "Task id: \(conversation.id)")
                    .padding(.bottom, 8)
                    .padding(.horizontal)
                
                Divider()
                
                    // MARK: - Messages ScrollView
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 4) {
                            ForEach(vm.activeMessages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                        }
                        .padding(.top, 10)
                    }
                    .onChange(of: vm.activeMessages.count) { _, _ in
                        scrollToBottom(proxy: proxy)
                    }
                    .onAppear {
                        scrollToBottom(proxy: proxy)
                    }
                }
                
                HStack(spacing: 8) {
                    TextField("Type a message...", text: $messageText)
                        .padding(12)
                        .background(backgroundColor)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .strokeBorder(.separator, lineWidth: 1)
                        )
                    
                    Button {
                        let text = messageText
                        messageText = ""
                        Task {
                            await vm.sendMessage(taskId: conversation.id, text: text)
                        }
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.blue)
                            .clipShape(Circle())
                    }
                }
                .padding()
            }
        }
        .onAppear {
            vm.listenToMessages(taskId: conversation.id)
        }
    }
    
        // MARK: - Helper Methods
    private func scrollToBottom(proxy: ScrollViewProxy) {
        guard let lastMessage = vm.activeMessages.last else { return }
        withAnimation {
            proxy.scrollTo(lastMessage.id, anchor: .bottom)
        }
    }
}
