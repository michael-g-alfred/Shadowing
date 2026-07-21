import Foundation
import FirebaseFirestore

final class ChatRepository: ChatRepositoryProtocol {
    private let db = Firestore.firestore()
    private let userRepo: UserRepositoryProtocol
    
    init(userRepo: UserRepositoryProtocol) {
        self.userRepo = userRepo
    }
    
    func createChat(taskId: String, requesterId: String, executorId: String) async throws {
        let chatData: [String: Any] = [
            "taskId": taskId,
            "participants": [requesterId, executorId],
            "requesterId": requesterId,
            "executorId": executorId,
            "lastMessage": "",
            "lastMessageTime": FieldValue.serverTimestamp(),
            "lastMessageStatus": MessageStatus.sent.rawValue
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
                            ?? UserSummaryModel(id: otherUserId, displayName: "User", avatarUrl: nil, rating: 0, totalRatings: 0, completedTasks: 0)
                            
                            DebugLogger.log("🔄 otherUser: \(otherUser)")
                            
                            let lastMessage = data["lastMessage"] as? String ?? ""
                            let statusRaw = data["lastMessageStatus"] as? String ?? "sent"
                            let status = MessageStatus(rawValue: statusRaw) ?? .sent
                            let timestamp = (data["lastMessageTime"] as? Timestamp)?.dateValue() ?? Date()
                            
                            conversations.append(
                                Conversation(
                                    id: id,
                                    otherUser: otherUser,
                                    lastMessage: lastMessage,
                                    lastMessageStatus: status,
                                    lastMessageTime: timestamp.formatted(date: .omitted, time: .shortened)
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
                            let statusRaw = data["status"] as? String ?? "sent"
                            let status = MessageStatus(rawValue: statusRaw)
                            let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                            let isCurrentUser = (senderId == currentUserId)
                            
                            let senderUser = (try? await self.userRepo.fetchUserSummary(id: senderId))
                            ?? UserSummaryModel(id: senderId, displayName: "User", avatarUrl: nil, rating: 0, totalRatings: 0, completedTasks: 0)
                            
                            messages.append(
                                ChatMessage(
                                    id: messageId,
                                    text: text,
                                    time: timestamp.formatted(date: .omitted, time: .shortened),
                                    sender: senderUser,
                                    isCurrentUser: isCurrentUser,
                                    status: isCurrentUser ? status : nil
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
        let messageRef = db.collection("chats").document(taskId).collection("messages").document()
        let messageData: [String: Any] = [
            "text": messageText,
            "senderId": senderId,
            "timestamp": FieldValue.serverTimestamp(),
            "status": MessageStatus.sent.rawValue
        ]
        
        do {
            try await messageRef.setData(messageData)
            try await db.collection("chats").document(taskId).updateData([
                "lastMessage": messageText,
                "lastMessageTime": FieldValue.serverTimestamp(),
                "lastMessageStatus": MessageStatus.sent.rawValue
            ])
            DebugLogger.log("✅ sendMessage succeeded | taskId: \(taskId)")
        } catch {
            DebugLogger.log("❌ sendMessage FAILED | taskId: \(taskId) | error: \(error)")
            throw error
        }
    }
    
    func markMessageAsRead(taskId: String, messageId: String) async throws {
        do {
            try await db.collection("chats")
                .document(taskId)
                .collection("messages")
                .document(messageId)
                .updateData(["status": MessageStatus.read.rawValue])
            DebugLogger.log("✅ markMessageAsRead succeeded | taskId: \(taskId) | messageId: \(messageId)")
        } catch {
            DebugLogger.log("❌ markMessageAsRead FAILED | taskId: \(taskId) | messageId: \(messageId) | error: \(error)")
            throw error
        }
    }
}
