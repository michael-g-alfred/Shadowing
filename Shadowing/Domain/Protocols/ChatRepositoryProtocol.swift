import Foundation

protocol ChatRepositoryProtocol: Sendable {
    func createChat(taskId: String, requesterId: String, executorId: String) async throws
    func deleteChat(taskId: String) async throws
    func observeConversations(currentUserId: String) -> AsyncStream<[Conversation]>
    func observeMessages(taskId: String, currentUserId: String) -> AsyncStream<[ChatMessage]>
    func sendMessage(taskId: String, messageText: String, senderId: String) async throws
    func markAllMessagesAsRead(taskId: String, currentUserId: String) async throws
    func setReaction(taskId: String, messageId: String, userId: String, emoji: String?) async throws
}
