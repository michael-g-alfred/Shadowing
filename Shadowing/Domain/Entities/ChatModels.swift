import Foundation

struct Conversation: Identifiable {
    let id: String
    let taskTitle: String
    let otherUser: UserSummaryModel
    let unreadCount: Int
}

struct ChatMessage: Identifiable {
    let id: String
    let text: String
    let time: String
    let sender: UserSummaryModel
    let isCurrentUser: Bool
    let reactions: [String: String] // [userId: emoji]
}
