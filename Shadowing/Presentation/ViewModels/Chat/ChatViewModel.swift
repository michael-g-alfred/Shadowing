import Foundation
import Observation

    // MARK: - Chat ViewModel

@MainActor
@Observable
final class ChatViewModel {
    
        // MARK: - Raw Data
    
        /// Raw conversations received from Firestore.
        ///
        /// This is the actual server state.
        /// The computed `conversations` property below applies
        /// the local read-state override for the currently-open chat.
    private var rawConversations: [Conversation] = []
    
        // MARK: - Derived Conversation State
    
        /// Single source of truth for read/unread state exposed to the UI.
        ///
        /// The currently-open conversation is always considered read locally,
        /// even if the Firestore snapshot still contains an unread count.
    var conversations: [Conversation] {
        guard let currentObservedTaskId else {
            return rawConversations
        }
        
        return rawConversations.map { conversation in
            guard conversation.id == currentObservedTaskId,
                  conversation.unreadCount != 0
            else {
                return conversation
            }
            
            return Conversation(
                id: conversation.id,
                taskTitle: conversation.taskTitle,
                otherUser: conversation.otherUser,
                unreadCount: 0
            )
        }
    }
    
        // MARK: - UI State
    
    var activeMessages: [ChatMessage] = []
    
    var isSending = false
    
    var isLoading = true
    
    var errorMessage: String?
    
    var totalUnreadCount: Int {
        conversations.reduce(0) {
            $0 + $1.unreadCount
        }
    }
    
        // MARK: - Dependencies
    
    private let authRepo: AuthRepositoryProtocol
    private let userRepo: UserRepositoryProtocol
    private let chatRepo: ChatRepositoryProtocol
    
        // MARK: - Listener Tasks
    
        /// Owns the conversation-list consuming task.
        ///
        /// Cancelling this task cancels consumption of the AsyncStream,
        /// which triggers the repository's `onTermination`,
        /// which removes the Firestore listener.
    private var conversationsTask:
    Task<Void, Never>?
    
        /// Owns the currently active message-list consuming task.
        ///
        /// Only one message listener can be active at a time.
    private var messagesTask:
    Task<Void, Never>?
    
        /// The task ID whose messages are currently being observed.
    private var currentObservedTaskId: String?
    
        // MARK: - Initialization
    
    init(
        authRepo: AuthRepositoryProtocol,
        userRepo: UserRepositoryProtocol,
        chatRepo: ChatRepositoryProtocol
    ) {
        self.authRepo = authRepo
        self.userRepo = userRepo
        self.chatRepo = chatRepo
    }
    
        // MARK: - Conversation Listening
    
        /// Starts observing the current user's conversations.
        ///
        /// Calling this method repeatedly while an existing listener is active
        /// is safe; it will not create duplicate Firestore listeners.
    func listenToConversations() {
        guard conversationsTask == nil else {
            return
        }
        
        guard let currentUserId =
                authRepo.currentUser?.id
        else {
            errorMessage =
            "Please login to continue"
            
            isLoading = false
            
            return
        }
        
        isLoading = true
        
        let chatRepo = chatRepo
        
        conversationsTask = Task { [weak self] in
            for await streamConversations in
                    chatRepo.observeConversations(
                        currentUserId: currentUserId
                    ) {
                
                guard !Task.isCancelled else {
                    return
                }
                
                guard let self else {
                    return
                }
                
                self.rawConversations =
                streamConversations
                
                self.isLoading = false
            }
        }
    }
    
        /// Cancels the conversation-list listener.
        ///
        /// Cancellation propagates to the AsyncStream consumer,
        /// which causes the repository's `onTermination`
        /// to remove the Firestore listener.
    func stopListeningToConversations() {
        conversationsTask?.cancel()
        conversationsTask = nil
    }
    
        /// Restarts the conversation listener.
        ///
        /// Useful for pull-to-refresh when you want to explicitly
        /// recreate the realtime subscription.
    func restartConversationsListener() {
        stopListeningToConversations()
        listenToConversations()
    }
    
        // MARK: - Message Listening
    
        /// Starts observing messages for a specific task.
        ///
        /// If the same task is already being observed, nothing happens.
        /// If another task is being observed, its listener is cancelled first.
    func listenToMessages(taskId: String) {
        if messagesTask != nil,
           currentObservedTaskId == taskId {
            return
        }
        
        guard let currentUserId =
                authRepo.currentUser?.id
        else {
            return
        }
        
            // Stop previous chat listener.
        messagesTask?.cancel()
        
        currentObservedTaskId = taskId
        
        let chatRepo = chatRepo
        
        messagesTask = Task { [weak self] in
            for await streamMessages in
                    chatRepo.observeMessages(
                        taskId: taskId,
                        currentUserId: currentUserId
                    ) {
                
                guard !Task.isCancelled else {
                    return
                }
                
                guard let self else {
                    return
                }
                
                self.activeMessages =
                streamMessages
            }
        }
    }
    
        /// Stops the currently active message listener.
    func stopListeningToMessages() {
        messagesTask?.cancel()
        messagesTask = nil
        
        currentObservedTaskId = nil
        activeMessages = []
    }
    
        // MARK: - Sending Messages
    
    func sendMessage(
        taskId: String,
        text: String
    ) async {
        let trimmedText =
        text.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        
        guard !trimmedText.isEmpty else {
            return
        }
        
        guard let currentUserId =
                authRepo.currentUser?.id
        else {
            return
        }
        
        isSending = true
        
        defer {
            isSending = false
        }
        
        do {
            try await chatRepo.sendMessage(
                taskId: taskId,
                messageText: trimmedText,
                senderId: currentUserId
            )
        } catch {
            errorMessage =
            error.localizedDescription
        }
    }
    
        // MARK: - Read State
    
    func markAsRead(
        taskId: String
    ) async {
        guard let currentUserId =
                authRepo.currentUser?.id
        else {
            return
        }
        
        do {
            try await chatRepo.markAllMessagesAsRead(
                taskId: taskId,
                currentUserId: currentUserId
            )
        } catch {
            DebugLogger.log(
                """
                ❌ markAsRead FAILED |
                taskId: \(taskId) |
                error: \(error)
                """
            )
        }
    }
    
        // MARK: - Current User
    
    var currentUserId: String? {
        authRepo.currentUser?.id
    }
    
        // MARK: - Reactions
    
    func toggleReaction(
        taskId: String,
        messageId: String,
        emoji: String
    ) async {
        guard let currentUserId =
                authRepo.currentUser?.id
        else {
            return
        }
        
        let currentReaction =
        activeMessages
            .first(where: {
                $0.id == messageId
            })?
            .reactions[currentUserId]
        
        let newEmoji: String? =
        currentReaction == emoji
        ? nil
        : emoji
        
        do {
            try await chatRepo.setReaction(
                taskId: taskId,
                messageId: messageId,
                userId: currentUserId,
                emoji: newEmoji
            )
        } catch {
            errorMessage =
            error.localizedDescription
        }
    }
}
