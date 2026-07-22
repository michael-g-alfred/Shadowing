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
    
    
    init(authRepo: AuthRepositoryProtocol, userRepo: UserRepositoryProtocol, chatRepo: ChatRepositoryProtocol) {
        self.authRepo = authRepo
        self.userRepo = userRepo
        self.chatRepo = chatRepo
    }
    
    func listenToConversations() {
        Task {
            guard let currentUserId = authRepo.currentUser?.id else {
                errorMessage = "Please login to continue"
                isLoading = false
                return
            }
            
            isLoading = true
            
            for await streamConversations in chatRepo.observeConversations(currentUserId: currentUserId) {
                self.conversations = streamConversations
                self.isLoading = false
            }
        }
    }
    
    func listenToMessages(taskId: String) {
        guard let currentUserId = authRepo.currentUser?.id else { return }
        Task {
            for await streamMessages in chatRepo.observeMessages(taskId: taskId, currentUserId: currentUserId) {
                self.activeMessages = streamMessages
            }
        }
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
