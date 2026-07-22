import Foundation

    // MARK: - Chat ViewModel
@MainActor
@Observable
final class ChatViewModel {
    var conversations: [Conversation] = []
    var activeMessages: [ChatMessage] = []
    var isSending: Bool = false
    var isLoading: Bool = true
    var errorMessage: String?
    
    var totalUnreadCount: Int {
        conversations.reduce(0) { $0 + $1.unreadCount }
    }
    
    private let authRepo: AuthRepositoryProtocol
    private let userRepo: UserRepositoryProtocol
    private let chatRepo: ChatRepositoryProtocol
    
        // MARK: - Listener task handles (prevents duplicate Firestore listeners)
    private var conversationsTask: Task<Void, Never>?
    private var messagesTask: Task<Void, Never>?
    private var currentObservedTaskId: String?
    
    init(authRepo: AuthRepositoryProtocol, userRepo: UserRepositoryProtocol, chatRepo: ChatRepositoryProtocol) {
        self.authRepo = authRepo
        self.userRepo = userRepo
        self.chatRepo = chatRepo
    }
    
    func listenToConversations() {
            // Already listening — don't spin up a second Firestore listener
        guard conversationsTask == nil else { return }
        
        guard let currentUserId = authRepo.currentUser?.id else {
            errorMessage = "Please login to continue"
            isLoading = false
            return
        }
        
        isLoading = true
        
        conversationsTask = Task { [weak self] in
            guard let self else { return }
            for await streamConversations in chatRepo.observeConversations(currentUserId: currentUserId) {
                if Task.isCancelled { break }
                self.conversations = streamConversations
                self.isLoading = false
            }
        }
    }
    
    func stopListeningToConversations() {
        conversationsTask?.cancel()
        conversationsTask = nil
    }
    
    func listenToMessages(taskId: String) {
            // Already listening to this exact chat — no-op
        if messagesTask != nil, currentObservedTaskId == taskId { return }
        
        guard let currentUserId = authRepo.currentUser?.id else { return }
        
            // Switching chats — cancel the previous listener first
        messagesTask?.cancel()
        currentObservedTaskId = taskId
        
        messagesTask = Task { [weak self] in
            guard let self else { return }
            for await streamMessages in chatRepo.observeMessages(taskId: taskId, currentUserId: currentUserId) {
                if Task.isCancelled { break }
                self.activeMessages = streamMessages
            }
        }
    }
    
    func stopListeningToMessages() {
        messagesTask?.cancel()
        messagesTask = nil
        currentObservedTaskId = nil
        activeMessages = []
    }
    
    func sendMessage(taskId: String, text: String) async {
        guard let currentUserId = authRepo.currentUser?.id, !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isSending = true
        defer { isSending = false }
        
        do {
            try await chatRepo.sendMessage(taskId: taskId, messageText: text, senderId: currentUserId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func markAsRead(taskId: String) async {
        guard let currentUserId = authRepo.currentUser?.id else { return }
        do {
            try await chatRepo.markAllMessagesAsRead(taskId: taskId, currentUserId: currentUserId)
        } catch {
            DebugLogger.log("❌ markAsRead FAILED | taskId: \(taskId) | error: \(error)")
        }
    }
    
    var currentUserId: String? {
        authRepo.currentUser?.id
    }
    
    func toggleReaction(taskId: String, messageId: String, emoji: String) async {
        guard let currentUserId = authRepo.currentUser?.id else { return }
        let currentReaction = activeMessages.first(where: { $0.id == messageId })?.reactions[currentUserId]
        let newEmoji: String? = (currentReaction == emoji) ? nil : emoji
        
        do {
            try await chatRepo.setReaction(taskId: taskId, messageId: messageId, userId: currentUserId, emoji: newEmoji)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
