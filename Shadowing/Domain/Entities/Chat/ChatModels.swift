import Foundation

struct Conversation: Identifiable {
    let id: String
    let otherUser: UserSummaryModel
    let lastMessage: String
    let lastMessageStatus: MessageStatus
    let lastMessageTime: String
    let unreadCount: Int
}

struct ChatMessage: Identifiable {
    let id: String
    let text: String
    let time: String
    let sender: UserSummaryModel
    let isCurrentUser: Bool
    let status: MessageStatus?
    let reactions: [String: String] // [userId: emoji]
}
