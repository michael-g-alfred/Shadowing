import SwiftUI

    // MARK: - Message Frame Preference Key
struct MessageFramePreferenceKey: PreferenceKey {
    static var defaultValue: [String: CGRect] = [:]
    
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

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
                
                if conversation.unreadCount > 0 {
                    Text("\(conversation.unreadCount)")
                        .font(.caption2.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.red)
                        .clipShape(Capsule())
                } else {
                    MessageStatusView(status: conversation.lastMessageStatus)
                }
            }
        }
    }
}

    // MARK: - Reaction Picker Component
struct ReactionPickerView: View {
    static let emojis = ["❤️", "👍", "😂", "😮", "😢", "🔥", "👏"]
    let onSelect: (String) -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(Self.emojis, id: \.self) { emoji in
                Text(emoji)
                    .font(.title)
                    .onTapGesture {
                        onSelect(emoji)
                    }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 0, style: .continuous)
                .fill(.thinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.accent.opacity(0.15))
                )
        )
        .clipShape(Capsule())
        .shadow(color: .accent.opacity(0.25), radius: 1, x: 0, y: 0)
        .glassEffect()
    }
}

    // MARK: - Reaction Badge Component
struct ReactionBadgeView: View {
    let reactions: [String: String]
    
    private var counts: [(emoji: String, count: Int)] {
        Dictionary(grouping: reactions.values, by: { $0 })
            .map { (emoji: $0.key, count: $0.value.count) }
            .sorted { $0.emoji < $1.emoji }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(counts, id: \.emoji) { item in
                Text(item.count > 1 ? "\(item.emoji) \(item.count)" : item.emoji)
                    .font(.caption2)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 0, style: .continuous)
                .fill(.thinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.accent.opacity(0.15))
                )
        )
        .clipShape(Capsule())
        .shadow(color: .accent.opacity(0.25), radius: 1, x: 0, y: 0)
        .glassEffect()
    }
}

    // MARK: - Message Bubble View
struct MessageBubble: View {
    let message: ChatMessage
    let onLongPress: () -> Void
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isCurrentUser {
                Spacer(minLength: 40)
            } else {
                AvatarView(profile: message.sender, size: 32, nameLayout: .none)
            }
            
            VStack(alignment: message.isCurrentUser ? .trailing : .leading, spacing: 4) {
                ZStack(alignment: message.isCurrentUser ? .bottomLeading : .bottomTrailing) {
                    Text(message.text)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(message.isCurrentUser ? Color.accent : Color(.systemGray3))
                        .foregroundColor(message.isCurrentUser ? .white : .primary)
                        .clipShape(Capsule())
                        .shadow(color: message.isCurrentUser ? .accent.opacity(0.5) : Color(.systemGray3).opacity(0.5), radius: 1, x: 0, y: 0)
                    
                    if !message.reactions.isEmpty {
                        ReactionBadgeView(reactions: message.reactions)
                            .alignmentGuide(VerticalAlignment.bottom) { d in
                                d[.bottom] - 15
                            }
                            .alignmentGuide(message.isCurrentUser ? HorizontalAlignment.leading : HorizontalAlignment.trailing) { d in
                                message.isCurrentUser ? d[.leading] + 10 : d[.trailing] - 10
                            }
                    }
                }
                .padding(.bottom, message.reactions.isEmpty ? 0 : 4)
                
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
                Spacer(minLength: 40)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .background(
            GeometryReader { geo in
                Color.clear
                    .preference(
                        key: MessageFramePreferenceKey.self,
                        value: [message.id: geo.frame(in: .global)]
                    )
            }
        )
        .contentShape(Rectangle())
        .onLongPressGesture(minimumDuration: 0.25) {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            onLongPress()
        }
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
    @State private var selectedMessageForReaction: ChatMessage? = nil
    @State private var messageFrames: [String: CGRect] = [:]
    
        // MARK: - Body
    var body: some View {
        GeometryReader { outerGeometry in
            ZStack {
                AppBackground()
                
                VStack(alignment: .leading, spacing: 0) {
                    AvatarView(profile: conversation.otherUser, size: 48, nameLayout: .horizontal, subtitle: "Task id: \(conversation.id)")
                        .padding()
                    
                    Divider()
                    
                        // MARK: - Messages Scroll View
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 6) {
                                ForEach(vm.activeMessages) { message in
                                    MessageBubble(message: message) {
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                            selectedMessageForReaction = message
                                        }
                                    }
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
                    .onPreferenceChange(MessageFramePreferenceKey.self) { frames in
                        self.messageFrames = frames
                    }
                    
                        // MARK: - Text Input Bar
                    HStack(spacing: 8) {
                        TextField("Type a message...", text: $messageText)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 0, style: .continuous)
                                    .fill(.thinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .fill(.accent.opacity(0.15))
                                    )
                            )
                            .clipShape(Capsule())
                            .shadow(color: .accent.opacity(0.25), radius: 1, x: 0, y: 0)
                            .glassEffect()
                        
                        Button {
                            let text = messageText
                            messageText = ""
                            Task {
                                await vm.sendMessage(taskId: conversation.id, text: text)
                            }
                        } label: {
                            Image(systemName: "paperplane.fill")
                                .foregroundColor(messageText.isEmpty ? .secondary : .white)
                                .padding(10)
                                .clipShape(Circle())
                        }
                        .buttonStyle(.glassProminent)
                        .disabled(messageText.isEmpty)
                    }
                    .padding()
                }
                
                    // MARK: - Reaction Overlay
                if let targetMessage = selectedMessageForReaction {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .onTapGesture {
                            dismissReactionOverlay()
                        }
                        .transition(.opacity)
                    
                    if let frame = messageFrames[targetMessage.id] {
                        ReactionPickerView { emoji in
                            Task {
                                await vm.toggleReaction(taskId: conversation.id, messageId: targetMessage.id, emoji: emoji)
                            }
                            dismissReactionOverlay()
                        }
                        .position(
                            x: outerGeometry.size.width / 2,
                            y: max(frame.minY - 45, 120)
                        )
                        .transition(.scale(scale: 0.8).combined(with: .opacity))
                        .zIndex(10)
                    }
                }
            }
        }
        .onAppear {
            vm.listenToMessages(taskId: conversation.id)
            Task {
                await vm.markAsRead(taskId: conversation.id)
            }
        }
    }
    
        // MARK: - Helper Methods
    private func dismissReactionOverlay() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            selectedMessageForReaction = nil
        }
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        guard let lastMessage = vm.activeMessages.last else { return }
        withAnimation {
            proxy.scrollTo(lastMessage.id, anchor: .bottom)
        }
    }
}
