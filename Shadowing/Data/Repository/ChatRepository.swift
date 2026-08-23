import Foundation
import FirebaseFirestore

    /// Manages real-time messaging over Firestore.
    ///
    /// Responsibilities:
    /// - Conversation realtime observation
    /// - Message realtime observation
    /// - Sending messages
    /// - Read receipts
    /// - Reactions
    /// - Chat creation/deletion
    /// - Chat-related notifications
    ///
    /// Lifecycle rule:
    ///
    /// Firestore listener
    ///        ↓
    /// AsyncStream
    ///        ↓
    /// consuming Task
    ///
    /// When the consuming Task is cancelled:
    ///
    /// Task cancellation
    ///        ↓
    /// AsyncStream termination
    ///        ↓
    /// continuation.onTermination
    ///        ↓
    /// Firestore listener.remove()
    ///
final class ChatRepository: ChatRepositoryProtocol {
    
        // MARK: - Firestore
    
    private let db = Firestore.firestore()
    
        // MARK: - Dependencies
    
    private let userRepo: UserRepositoryProtocol
    private let taskRepo: TaskRepositoryProtocol
    private let notificationRepo: NotificationRepositoryProtocol
    
        // MARK: - Initialization
    
    init(
        userRepo: UserRepositoryProtocol,
        taskRepo: TaskRepositoryProtocol,
        notificationRepo: NotificationRepositoryProtocol
    ) {
        self.userRepo = userRepo
        self.taskRepo = taskRepo
        self.notificationRepo = notificationRepo
    }
    
        // MARK: - Tombstone User
    
        /// Creates an explicit placeholder for a participant/sender
        /// whose profile could not be resolved.
    private static func tombstoneUserSummary(
        id: String
    ) -> UserSummaryModel {
        UserSummaryModel(
            id: id,
            displayName: String(
                localized:
                    "chat.participant.unavailable",
                defaultValue:
                    "Unavailable User"
            ),
            email: "",
            avatarUrl: nil,
            bio: "",
            rating: 0,
            totalRatings: 0,
            completedTasks: 0,
            specialties: []
        )
    }
    
        // MARK: - Create Chat
    
    func createChat(
        taskId: String,
        requesterId: String,
        executorId: String
    ) async throws {
        
        let chatData: [String: Any] = [
            "taskId": taskId,
            "participants": [
                requesterId,
                executorId
            ],
            "requesterId": requesterId,
            "executorId": executorId,
            "lastMessage": "",
            "lastMessageTime":
                FieldValue.serverTimestamp(),
            "unreadCounts": [
                requesterId: 0,
                executorId: 0
            ]
        ]
        
        DebugLogger.log(
            "👤 requesterId: \(requesterId) | executorId: \(executorId)"
        )
        
        do {
            try await db
                .collection("chats")
                .document(taskId)
                .setData(
                    chatData,
                    merge: true
                )
            
            DebugLogger.log(
                "✅ createChat succeeded for taskId: \(taskId)"
            )
            
        } catch let firestoreError
                    as NSError
                    where firestoreError.domain
                    == FirestoreErrorDomain
                    &&
                    firestoreError.code
                    == FirestoreErrorCode
            .permissionDenied.rawValue {
            
            DebugLogger.log(
                """
                ❌ createChat PERMISSION DENIED |
                taskId: \(taskId) |
                error: \(firestoreError)
                """
            )
            
            throw ChatError.permissionDenied
            
        } catch {
            DebugLogger.log(
                """
                ❌ createChat FAILED |
                taskId: \(taskId) |
                error: \(error)
                """
            )
            
            throw ChatError.firestoreError(
                underlying: error
            )
        }
    }
    
        // MARK: - Delete Chat
    
    func deleteChat(
        taskId: String
    ) async throws {
        
        let chatRef =
        db.collection("chats")
            .document(taskId)
        
            // Read participants before deleting
            // the chat document.
        let chatSnapshot =
        try? await chatRef.getDocument()
        
        let participants =
        chatSnapshot?
            .data()?["participants"]
        as? [String]
        ?? []
        
            // Delete all messages.
        let messagesSnapshot =
        try await chatRef
            .collection("messages")
            .getDocuments()
        
        for document
                in messagesSnapshot.documents {
            
            try await document.reference.delete()
        }
        
            // Delete chat document.
        try await chatRef.delete()
        
            // Notification cleanup is best effort.
        for participantId in participants {
            do {
                try await notificationRepo
                    .deleteNotifications(
                        userId: participantId,
                        taskId: taskId
                    )
            } catch {
                DebugLogger.log(
                    """
                    ❌ deleteNotifications FAILED |
                    userId: \(participantId) |
                    taskId: \(taskId) |
                    error: \(error)
                    """
                )
            }
        }
    }
    
        // MARK: - Observe Conversations
    
    func observeConversations(
        currentUserId: String
    ) -> AsyncStream<[Conversation]> {
        
        DebugLogger.log(
            """
            👂 observeConversations STARTED |
            currentUserId: \(currentUserId)
            """
        )
        
        return AsyncStream<[Conversation]> {
            continuation in
            
            let generationBox =
            SnapshotGenerationBox()
            
            let listener =
            db.collection("chats")
                .whereField(
                    "participants",
                    arrayContains: currentUserId
                )
                .addSnapshotListener {
                    [weak self]
                    snapshot,
                    error in
                    
                    if let error {
                        DebugLogger.log(
                                """
                                🔥 observeConversations FIRESTORE ERROR: \
                                \(error.localizedDescription) |
                                full: \(error)
                                """
                        )
                    }
                    
                    DebugLogger.log(
                            """
                            📥 observeConversations snapshot |
                            docs count: \
                            \(snapshot?.documents.count ?? -1) |
                            isFromCache: \
                            \(snapshot?.metadata.isFromCache ?? false)
                            """
                    )
                    
                    guard
                        let self,
                        let documents =
                            snapshot?.documents,
                        error == nil
                    else {
                        DebugLogger.log(
                                """
                                ⚠️ observeConversations bailing out —
                                yielding empty array
                                """
                        )
                        
                        continuation.yield([])
                        
                        return
                    }
                    
                    let generation =
                    generationBox.next()
                    
                    Task {
                        let conversations =
                        await self
                            .resolveConversations(
                                documents: documents,
                                currentUserId:
                                    currentUserId
                            )
                        
                        guard generationBox
                            .isCurrent(generation)
                        else {
                            DebugLogger.log(
                                    """
                                    ⏭️ observeConversations dropping
                                    stale snapshot |
                                    generation: \(generation)
                                    """
                            )
                            
                            return
                        }
                        
                        DebugLogger.log(
                                """
                                ✅ observeConversations yielding
                                \(conversations.count) conversations
                                """
                        )
                        
                        continuation.yield(
                            conversations
                        )
                    }
                }
            
            continuation.onTermination = {
                [weak listener] _ in
                
                listener?.remove()
                
                DebugLogger.log(
                    """
                    🛑 observeConversations TERMINATED |
                    currentUserId: \(currentUserId)
                    """
                )
            }
        }
    }
    
        // MARK: - Resolve Conversations
    
    private func resolveConversations(
        documents: [QueryDocumentSnapshot],
        currentUserId: String
    ) async -> [Conversation] {
        
        await withTaskGroup(
            of: (Int, Conversation).self
        ) { group in
            
            for (
                index,
                document
            ) in documents.enumerated() {
                
                group.addTask { [self] in
                    
                    let data =
                    document.data()
                    
                    let id =
                    document.documentID
                    
                    let requesterId =
                    data["requesterId"]
                    as? String
                    ?? ""
                    
                    let executorId =
                    data["executorId"]
                    as? String
                    ?? ""
                    
                    let otherUserId =
                    currentUserId == requesterId
                    ? executorId
                    : requesterId
                    
                    async let otherUserFetch:
                    UserSummaryModel = {
                        
                        do {
                            return try await self
                                .userRepo
                                .fetchUserSummary(
                                    id: otherUserId
                                )
                        } catch {
                            DebugLogger.log(
                                    """
                                    ⚠️ resolveConversations failed
                                    to fetch participant
                                    \(otherUserId): \(error)
                                    """
                            )
                            
                            return Self
                                .tombstoneUserSummary(
                                    id: otherUserId
                                )
                        }
                    }()
                    
                    async let taskTitleFetch:
                    String =
                    (try? await self.taskRepo
                        .getTaskDetails(id: id))?
                        .title
                    ?? "Task"
                    
                    let otherUser =
                    await otherUserFetch
                    
                    let taskTitle =
                    await taskTitleFetch
                    
                    let unreadCounts =
                    data["unreadCounts"]
                    as? [String: Int]
                    ?? [:]
                    
                    let unreadCount =
                    unreadCounts[currentUserId]
                    ?? 0
                    
                    let conversation =
                    Conversation(
                        id: id,
                        taskTitle: taskTitle,
                        otherUser: otherUser,
                        unreadCount: unreadCount
                    )
                    
                    return (
                        index,
                        conversation
                    )
                }
            }
            
            var results:
            [(Int, Conversation)] = []
            
            for await result in group {
                results.append(result)
            }
            
            return results
                .sorted {
                    $0.0 < $1.0
                }
                .map(\.1)
        }
    }
    
        // MARK: - Observe Messages
    
    func observeMessages(
        taskId: String,
        currentUserId: String
    ) -> AsyncStream<[ChatMessage]> {
        
        DebugLogger.log(
            """
            👂 observeMessages STARTED |
            taskId: \(taskId) |
            currentUserId: \(currentUserId)
            """
        )
        
        return AsyncStream<[ChatMessage]> {
            continuation in
            
            let generationBox =
            SnapshotGenerationBox()
            
            let listener =
            db.collection("chats")
                .document(taskId)
                .collection("messages")
                .order(
                    by: "timestamp",
                    descending: false
                )
                .addSnapshotListener {
                    [weak self]
                    snapshot,
                    error in
                    
                    if let error {
                        DebugLogger.log(
                                """
                                🔥 observeMessages FIRESTORE ERROR: \
                                \(error.localizedDescription) |
                                full: \(error)
                                """
                        )
                    }
                    
                    DebugLogger.log(
                            """
                            📥 observeMessages snapshot |
                            taskId: \(taskId) |
                            docs count: \
                            \(snapshot?.documents.count ?? -1)
                            """
                    )
                    
                    guard
                        let self,
                        let documents =
                            snapshot?.documents,
                        error == nil
                    else {
                        DebugLogger.log(
                                """
                                ⚠️ observeMessages bailing out —
                                yielding empty array
                                """
                        )
                        
                        continuation.yield([])
                        
                        return
                    }
                    
                    let generation =
                    generationBox.next()
                    
                    Task {
                        let messages =
                        await self.resolveMessages(
                            documents: documents,
                            currentUserId:
                                currentUserId
                        )
                        
                        guard generationBox
                            .isCurrent(generation)
                        else {
                            DebugLogger.log(
                                    """
                                    ⏭️ observeMessages dropping stale
                                    snapshot |
                                    taskId: \(taskId) |
                                    generation: \(generation)
                                    """
                            )
                            
                            return
                        }
                        
                        DebugLogger.log(
                                """
                                ✅ observeMessages yielding
                                \(messages.count) messages |
                                taskId: \(taskId)
                                """
                        )
                        
                        continuation.yield(
                            messages
                        )
                    }
                }
            
            continuation.onTermination = {
                [weak listener] _ in
                
                listener?.remove()
                
                DebugLogger.log(
                    """
                    🛑 observeMessages TERMINATED |
                    taskId: \(taskId)
                    """
                )
            }
        }
    }
    
        // MARK: - Resolve Messages
    
    private func resolveMessages(
        documents: [QueryDocumentSnapshot],
        currentUserId: String
    ) async -> [ChatMessage] {
        
        await withTaskGroup(
            of: (Int, ChatMessage).self
        ) { group in
            
            for (
                index,
                document
            ) in documents.enumerated() {
                
                group.addTask { [self] in
                    
                    let data =
                    document.data()
                    
                    let messageId =
                    document.documentID
                    
                    let text =
                    data["text"]
                    as? String
                    ?? ""
                    
                    let senderId =
                    data["senderId"]
                    as? String
                    ?? ""
                    
                    let timestamp =
                    (
                        data["timestamp"]
                        as? Timestamp
                    )?
                        .dateValue()
                    ?? Date()
                    
                    let isCurrentUser =
                    senderId == currentUserId
                    
                    let reactions =
                    data["reactions"]
                    as? [String: String]
                    ?? [:]
                    
                    let senderUser:
                    UserSummaryModel
                    
                    do {
                        senderUser =
                        try await self.userRepo
                            .fetchUserSummary(
                                id: senderId
                            )
                    } catch {
                        DebugLogger.log(
                            """
                            ⚠️ resolveMessages failed
                            to fetch sender
                            \(senderId): \(error)
                            """
                        )
                        
                        senderUser =
                        Self.tombstoneUserSummary(
                            id: senderId
                        )
                    }
                    
                    let message =
                    ChatMessage(
                        id: messageId,
                        text: text,
                        time: timestamp.formatted(
                            date: .omitted,
                            time: .shortened
                        ),
                        sender: senderUser,
                        isCurrentUser:
                            isCurrentUser,
                        reactions: reactions
                    )
                    
                    return (
                        index,
                        message
                    )
                }
            }
            
            var results:
            [(Int, ChatMessage)] = []
            
            for await result in group {
                results.append(result)
            }
            
            return results
                .sorted {
                    $0.0 < $1.0
                }
                .map(\.1)
        }
    }
    
        // MARK: - Send Message
    
    func sendMessage(
        taskId: String,
        messageText: String,
        senderId: String
    ) async throws {
        
        DebugLogger.log(
            """
            ➡️ sendMessage called |
            taskId: \(taskId) |
            senderId: \(senderId)
            """
        )
        
        let chatRef =
        db.collection("chats")
            .document(taskId)
        
        let messageRef =
        chatRef
            .collection("messages")
            .document()
        
        let messageData:
        [String: Any] = [
            "text": messageText,
            "senderId": senderId,
            "timestamp":
                FieldValue.serverTimestamp()
        ]
        
        do {
            try await messageRef
                .setData(messageData)
            
            let chatSnapshot =
            try await chatRef.getDocument()
            
            let participants =
            chatSnapshot
                .data()?["participants"]
            as? [String]
            ?? []
            
            let recipientId =
            participants.first {
                $0 != senderId
            }
            
            var chatUpdateData:
            [String: Any] = [
                "lastMessage":
                    messageText,
                "lastMessageTime":
                    FieldValue.serverTimestamp()
            ]
            
            if let recipientId {
                chatUpdateData[
                    "unreadCounts.\(recipientId)"
                ] =
                FieldValue.increment(
                    Int64(1)
                )
            }
            
            try await chatRef
                .updateData(
                    chatUpdateData
                )
            
            DebugLogger.log(
                """
                ✅ sendMessage succeeded |
                taskId: \(taskId)
                """
            )
            
            if let recipientId {
                await createNewMessageNotification(
                    recipientId: recipientId,
                    senderId: senderId,
                    taskId: taskId,
                    messageText: messageText
                )
            }
            
        } catch {
            DebugLogger.log(
                """
                ❌ sendMessage FAILED |
                taskId: \(taskId) |
                error: \(error)
                """
            )
            
            throw error
        }
    }
    
        // MARK: - New Message Notification
    
    private func createNewMessageNotification(
        recipientId: String,
        senderId: String,
        taskId: String,
        messageText: String
    ) async {
        
        let senderName =
        (
            try? await userRepo
                .fetchUserSummary(
                    id: senderId
                )
        )?
            .displayName
        ?? String(
            localized:
                "notification.newMessage.fallbackTitle"
        )
        
        do {
            try await notificationRepo.send(
                to: recipientId,
                type: .newMessage,
                subjectText: senderName,
                messageText: messageText,
                taskId: taskId
            )
            
            DebugLogger.log(
                """
                ✅ createNewMessageNotification succeeded |
                recipientId: \(recipientId) |
                taskId: \(taskId)
                """
            )
            
        } catch {
            DebugLogger.log(
                """
                ❌ createNewMessageNotification FAILED |
                recipientId: \(recipientId) |
                error: \(error)
                """
            )
        }
    }
    
        // MARK: - Mark Messages As Read
    
    func markAllMessagesAsRead(
        taskId: String,
        currentUserId: String
    ) async throws {
        
        let chatRef =
        db.collection("chats")
            .document(taskId)
        
        do {
            try await chatRef.updateData(
                [
                    "unreadCounts.\(currentUserId)": 0
                ]
            )
            
            DebugLogger.log(
                """
                ✅ markAllMessagesAsRead succeeded |
                taskId: \(taskId) |
                currentUserId: \(currentUserId)
                """
            )
            
        } catch {
            DebugLogger.log(
                """
                ❌ markAllMessagesAsRead FAILED |
                taskId: \(taskId) |
                error: \(error)
                """
            )
            
            throw error
        }
    }
    
        // MARK: - Reactions
    
    func setReaction(
        taskId: String,
        messageId: String,
        userId: String,
        emoji: String?
    ) async throws {
        
        let messageRef =
        db.collection("chats")
            .document(taskId)
            .collection("messages")
            .document(messageId)
        
        do {
            if let emoji {
                try await messageRef.updateData(
                    [
                        "reactions.\(userId)": emoji
                    ]
                )
            } else {
                try await messageRef.updateData(
                    [
                        "reactions.\(userId)":
                            FieldValue.delete()
                    ]
                )
            }
            
            DebugLogger.log(
                """
                ✅ setReaction succeeded |
                taskId: \(taskId) |
                messageId: \(messageId) |
                emoji: \(emoji ?? "removed")
                """
            )
            
        } catch {
            DebugLogger.log(
                """
                ❌ setReaction FAILED |
                taskId: \(taskId) |
                messageId: \(messageId) |
                error: \(error)
                """
            )
            
            throw error
        }
    }
}

    // MARK: - Snapshot Generation Tracking

private final class SnapshotGenerationBox:
    @unchecked Sendable {
    
    private let lock = NSLock()
    
    private var latest = 0
    
    func next() -> Int {
        lock.lock()
        defer {
            lock.unlock()
        }
        
        latest += 1
        
        return latest
    }
    
    func isCurrent(
        _ generation: Int
    ) -> Bool {
        lock.lock()
        defer {
            lock.unlock()
        }
        
        return generation == latest
    }
}
