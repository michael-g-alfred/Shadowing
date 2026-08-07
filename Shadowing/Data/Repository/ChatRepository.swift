import Foundation
import FirebaseFirestore

final class ChatRepository: ChatRepositoryProtocol {
    private let db = Firestore.firestore()
    private let userRepo: UserRepositoryProtocol
    private let taskRepo: TaskRepositoryProtocol
    
    init(userRepo: UserRepositoryProtocol, taskRepo: TaskRepositoryProtocol) {
        self.userRepo = userRepo
        self.taskRepo = taskRepo
    }
    
    func createChat(taskId: String, requesterId: String, executorId: String) async throws {
        let chatData: [String: Any] = [
            "taskId": taskId,
            "participants": [requesterId, executorId],
            "requesterId": requesterId,
            "executorId": executorId,
            "lastMessage": "",
            "lastMessageTime": FieldValue.serverTimestamp(),
            "unreadCounts": [requesterId: 0, executorId: 0]
        ]
        DebugLogger.log("👤 requesterId: \(requesterId) | executorId: \(executorId)")
        do {
            try await db.collection("chats").document(taskId).setData(chatData, merge: true)
            DebugLogger.log("✅ createChat succeeded for taskId: \(taskId)")
        } catch {
            DebugLogger.log("❌ createChat FAILED for taskId: \(taskId) | error: \(error)")
            throw error
        }
    }
    
    func deleteChat(taskId: String) async throws {
        let chatRef = db.collection("chats").document(taskId)
        let messagesSnapshot = try await chatRef.collection("messages").getDocuments()
        for doc in messagesSnapshot.documents {
            try await doc.reference.delete()
        }
        try await chatRef.delete()
    }
    
    func observeConversations(currentUserId: String) -> AsyncStream<[Conversation]> {
        DebugLogger.log("👂 observeConversations STARTED listening for currentUserId: \(currentUserId)")
        return AsyncStream([Conversation].self) { continuation in
            let listener = db.collection("chats")
                .whereField("participants", arrayContains: currentUserId)
                .addSnapshotListener { [weak self] snapshot, error in
                    
                    if let error = error {
                        DebugLogger.log("🔥 observeConversations FIRESTORE ERROR: \(error.localizedDescription) | full: \(error)")
                    }
                    DebugLogger.log("📥 observeConversations snapshot | docs count: \(snapshot?.documents.count ?? -1) | isFromCache: \(snapshot?.metadata.isFromCache ?? false)")
                    
                    guard let self = self, let documents = snapshot?.documents, error == nil else {
                        DebugLogger.log("⚠️ observeConversations bailing out — yielding empty array")
                        continuation.yield([])
                        return
                    }
                    
                    Task {
                        var conversations: [Conversation] = []
                        
                        for doc in documents {
                            let data = doc.data()
                            let id = doc.documentID
                            let requesterId = data["requesterId"] as? String ?? ""
                            let executorId = data["executorId"] as? String ?? ""
                            let otherUserId = (currentUserId == requesterId) ? executorId : requesterId
                            
                            DebugLogger.log("🔄 currentUserId: \(currentUserId) | requesterId: \(requesterId) | executorId: \(executorId) | otherUserId: \(otherUserId)")
                            
                            let otherUser = (try? await self.userRepo.fetchUserSummary(id: otherUserId))
                            ?? UserSummaryModel(id: otherUserId, displayName: "User", email: "", avatarUrl: nil, bio: "", rating: 0, totalRatings: 0, completedTasks: 0, specialties: [])
                            
                            DebugLogger.log("🔄 otherUser: \(otherUser)")
                            
                            let taskTitle = (try? await self.taskRepo.getTaskDetails(id: id))?.title ?? "Task"
                            
                            let unreadCounts = data["unreadCounts"] as? [String: Int] ?? [:]
                            let unreadCount = unreadCounts[currentUserId] ?? 0
                            
                            conversations.append(
                                Conversation(
                                    id: id,
                                    taskTitle: taskTitle,
                                    otherUser: otherUser,
                                    unreadCount: unreadCount
                                )
                            )
                        }
                        DebugLogger.log("✅ observeConversations yielding \(conversations.count) conversations")
                        continuation.yield(conversations)
                    }
                }
            
            continuation.onTermination = { _ in
                DebugLogger.log("🛑 observeConversations listener terminated")
                listener.remove()
            }
        }
    }
    
    func observeMessages(taskId: String, currentUserId: String) -> AsyncStream<[ChatMessage]> {
        DebugLogger.log("👂 observeMessages STARTED listening for taskId: \(taskId) | currentUserId: \(currentUserId)")
        return AsyncStream { continuation in
            let listener = db.collection("chats")
                .document(taskId)
                .collection("messages")
                .order(by: "timestamp", descending: false)
                .addSnapshotListener { [weak self] snapshot, error in
                    
                    if let error = error {
                        DebugLogger.log("🔥 observeMessages FIRESTORE ERROR: \(error.localizedDescription) | full: \(error)")
                    }
                    DebugLogger.log("📥 observeMessages snapshot | taskId: \(taskId) | docs count: \(snapshot?.documents.count ?? -1)")
                    
                    guard let self = self, let documents = snapshot?.documents, error == nil else {
                        DebugLogger.log("⚠️ observeMessages bailing out — yielding empty array")
                        continuation.yield([])
                        return
                    }
                    
                    Task {
                        var messages: [ChatMessage] = []
                        for doc in documents {
                            let data = doc.data()
                            let messageId = doc.documentID
                            let text = data["text"] as? String ?? ""
                            let senderId = data["senderId"] as? String ?? ""
                            let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                            let isCurrentUser = (senderId == currentUserId)
                            let reactions = data["reactions"] as? [String: String] ?? [:]
                            
                            let senderUser = (try? await self.userRepo.fetchUserSummary(id: senderId))
                            ?? UserSummaryModel(id: senderId, displayName: "User", email: "", avatarUrl: nil, bio: "", rating: 0, totalRatings: 0, completedTasks: 0, specialties: [])
                            
                            messages.append(
                                ChatMessage(
                                    id: messageId,
                                    text: text,
                                    time: timestamp.formatted(date: .omitted, time: .shortened),
                                    sender: senderUser,
                                    isCurrentUser: isCurrentUser,
                                    reactions: reactions
                                )
                            )
                        }
                        DebugLogger.log("✅ observeMessages yielding \(messages.count) messages for taskId: \(taskId)")
                        continuation.yield(messages)
                    }
                }
            
            continuation.onTermination = { _ in
                DebugLogger.log("🛑 observeMessages listener terminated for taskId: \(taskId)")
                listener.remove()
            }
        }
    }
    
    func sendMessage(taskId: String, messageText: String, senderId: String) async throws {
        DebugLogger.log("➡️ sendMessage called | taskId: \(taskId) | senderId: \(senderId)")
        let chatRef = db.collection("chats").document(taskId)
        let messageRef = chatRef.collection("messages").document()
        let messageData: [String: Any] = [
            "text": messageText,
            "senderId": senderId,
            "timestamp": FieldValue.serverTimestamp()
        ]
        
        do {
            try await messageRef.setData(messageData)
            
                // Determine recipient to bump their unread counter
            let chatSnapshot = try await chatRef.getDocument()
            let participants = chatSnapshot.data()?["participants"] as? [String] ?? []
            let recipientId = participants.first(where: { $0 != senderId })
            
            var chatUpdateData: [String: Any] = [
                "lastMessage": messageText,
                "lastMessageTime": FieldValue.serverTimestamp()
            ]
            if let recipientId {
                chatUpdateData["unreadCounts.\(recipientId)"] = FieldValue.increment(Int64(1))
            }
            
            try await chatRef.updateData(chatUpdateData)
            DebugLogger.log("✅ sendMessage succeeded | taskId: \(taskId)")
        } catch {
            DebugLogger.log("❌ sendMessage FAILED | taskId: \(taskId) | error: \(error)")
            throw error
        }
    }
    
    func markAllMessagesAsRead(taskId: String, currentUserId: String) async throws {
        let chatRef = db.collection("chats").document(taskId)
        do {
                // Reset this user's unread counter on the chat doc (drives the tab badge)
            try await chatRef.updateData(["unreadCounts.\(currentUserId)": 0])
            DebugLogger.log("✅ markAllMessagesAsRead succeeded | taskId: \(taskId) | currentUserId: \(currentUserId)")
        } catch {
            DebugLogger.log("❌ markAllMessagesAsRead FAILED | taskId: \(taskId) | error: \(error)")
            throw error
        }
    }
    
    func setReaction(taskId: String, messageId: String, userId: String, emoji: String?) async throws {
        let messageRef = db.collection("chats")
            .document(taskId)
            .collection("messages")
            .document(messageId)
        
        do {
            if let emoji {
                try await messageRef.updateData(["reactions.\(userId)": emoji])
            } else {
                try await messageRef.updateData(["reactions.\(userId)": FieldValue.delete()])
            }
            DebugLogger.log("✅ setReaction succeeded | taskId: \(taskId) | messageId: \(messageId) | emoji: \(emoji ?? "removed")")
        } catch {
            DebugLogger.log("❌ setReaction FAILED | taskId: \(taskId) | messageId: \(messageId) | error: \(error)")
            throw error
        }
    }
}
