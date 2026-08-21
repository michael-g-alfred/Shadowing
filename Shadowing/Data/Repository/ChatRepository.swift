import Foundation
import FirebaseFirestore

/// Manages real-time messaging over Firestore: the conversation list,
/// per-task message threads, sending, read receipts, reactions, and chat
/// lifecycle (create/delete tied to task assignment/completion).
///
/// Firestore shape:
/// ```
/// chats/{taskId}
///   taskId, participants: [String], requesterId, executorId,
///   lastMessage, lastMessageTime, unreadCounts: {userId: Int}
///   messages/{messageId}
///     text, senderId, timestamp, reactions: {userId: emoji}
/// ```
///
/// This is the only repository that composes three others
/// (``UserRepositoryProtocol``, ``TaskRepositoryProtocol``,
/// ``NotificationRepositoryProtocol``), since resolving a conversation or
/// message requires sender/participant info and task titles, and sending a
/// message triggers a notification.
final class ChatRepository: ChatRepositoryProtocol {

    /// Firestore database handle.
    private let db = Firestore.firestore()

    /// Used to resolve participant/sender summaries for conversations and messages.
    private let userRepo: UserRepositoryProtocol

    /// Used to resolve task titles for conversations.
    private let taskRepo: TaskRepositoryProtocol

    /// Used to create/clean up chat-related notifications.
    private let notificationRepo: NotificationRepositoryProtocol

    /// Creates a chat repository.
    ///
    /// - Parameters:
    ///   - userRepo: Used to resolve participant/sender summaries.
    ///   - taskRepo: Used to resolve task titles.
    ///   - notificationRepo: Used to create/clean up notifications.
    init(userRepo: UserRepositoryProtocol, taskRepo: TaskRepositoryProtocol, notificationRepo: NotificationRepositoryProtocol) {
        self.userRepo = userRepo
        self.taskRepo = taskRepo
        self.notificationRepo = notificationRepo
    }

    /// Creates (or upserts) the chat document for a task, when it gets assigned.
    ///
    /// - Parameters:
    ///   - taskId: The task's ID; also used as the chat document's ID.
    ///   - requesterId: The task requester's user ID.
    ///   - executorId: The assigned executor's user ID.
    /// - Throws: A Firestore error if the write fails.
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

    /// Deletes a task's chat: all message documents, the chat document
    /// itself, and both participants' stale `newMessage` notifications for
    /// that task.
    ///
    /// Participants are read *before* the chat document is deleted (since
    /// they'd otherwise be unrecoverable afterward). Notification cleanup
    /// is best-effort per participant — a failure for one participant is
    /// logged but does not abort cleanup for the other.
    ///
    /// - Parameter taskId: The task whose chat should be deleted.
    /// - Throws: A Firestore error if message or chat-document deletion fails.
    func deleteChat(taskId: String) async throws {
        let chatRef = db.collection("chats").document(taskId)

        // Grab participants before the doc is gone, so we can clean up
        // their stale `newMessage` notifications for this task afterward.
        let chatSnapshot = try? await chatRef.getDocument()
        let participants = chatSnapshot?.data()?["participants"] as? [String] ?? []

        let messagesSnapshot = try await chatRef.collection("messages").getDocuments()
        for doc in messagesSnapshot.documents {
            try await doc.reference.delete()
        }
        try await chatRef.delete()

        for participantId in participants {
            do {
                try await notificationRepo.deleteNotifications(userId: participantId, taskId: taskId)
            } catch {
                DebugLogger.log("❌ deleteNotifications FAILED | userId: \(participantId) | taskId: \(taskId) | error: \(error)")
            }
        }
    }

    /// Observes the current user's chats in real time.
    ///
    /// Each Firestore snapshot is resolved into `[Conversation]` by fetching
    /// the other participant's summary and the task's title for every chat
    /// **in parallel** via a `TaskGroup`, instead of sequentially awaiting
    /// one chat at a time.
    ///
    /// A monotonically increasing snapshot generation (see
    /// ``SnapshotGenerationBox``) guards against out-of-order yields: if
    /// snapshot A starts resolving, then snapshot B arrives and finishes
    /// first, A's result — being stale by the time it completes — is
    /// dropped instead of overwriting B's newer data.
    ///
    /// - Parameter currentUserId: The signed-in user's ID.
    /// - Returns: An `AsyncStream` that yields the latest `[Conversation]`
    ///   list every time the underlying chat data changes. Yields an empty
    ///   array on listener errors.
    func observeConversations(currentUserId: String) -> AsyncStream<[Conversation]> {
        DebugLogger.log("👂 observeConversations STARTED listening for currentUserId: \(currentUserId)")
        return AsyncStream([Conversation].self) { continuation in
            let generationBox = SnapshotGenerationBox()

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

                    let myGeneration = generationBox.next()

                    Task {
                        let conversations = await self.resolveConversations(
                            documents: documents,
                            currentUserId: currentUserId
                        )

                        // Drop this result if a newer snapshot has already
                        // started (and possibly finished) resolving.
                        guard generationBox.isCurrent(myGeneration) else {
                            DebugLogger.log("⏭️ observeConversations dropping stale snapshot (generation \(myGeneration))")
                            return
                        }

                        DebugLogger.log("✅ observeConversations yielding \(conversations.count) conversations")
                        continuation.yield(conversations)
                    }
                }

            continuation.onTermination = { _ in
                listener.remove()
            }
        }
    }

    /// Resolves all chat documents into `Conversation`s concurrently.
    ///
    /// - Parameters:
    ///   - documents: The chat documents from a Firestore snapshot.
    ///   - currentUserId: The signed-in user's ID, used to determine the
    ///     "other" participant and this user's unread count.
    /// - Returns: The resolved conversations, in the same order as `documents`.
    private func resolveConversations(
        documents: [QueryDocumentSnapshot],
        currentUserId: String
    ) async -> [Conversation] {
        await withTaskGroup(of: (Int, Conversation).self) { group in
            for (index, doc) in documents.enumerated() {
                group.addTask {
                    let data = doc.data()
                    let id = doc.documentID
                    let requesterId = data["requesterId"] as? String ?? ""
                    let executorId = data["executorId"] as? String ?? ""
                    let otherUserId = (currentUserId == requesterId) ? executorId : requesterId

                    async let otherUserFetch = (try? await self.userRepo.fetchUserSummary(id: otherUserId))
                    ?? UserSummaryModel(id: otherUserId, displayName: "User", email: "", avatarUrl: nil, bio: "", rating: 0, totalRatings: 0, completedTasks: 0, specialties: [])

                    async let taskTitleFetch = (try? await self.taskRepo.getTaskDetails(id: id))?.title ?? "Task"

                    let otherUser = await otherUserFetch
                    let taskTitle = await taskTitleFetch

                    let unreadCounts = data["unreadCounts"] as? [String: Int] ?? [:]
                    let unreadCount = unreadCounts[currentUserId] ?? 0

                    let conversation = Conversation(
                        id: id,
                        taskTitle: taskTitle,
                        otherUser: otherUser,
                        unreadCount: unreadCount
                    )
                    return (index, conversation)
                }
            }

            // Collect and restore original document order (TaskGroup
            // completion order is not guaranteed to match input order).
            var results: [(Int, Conversation)] = []
            for await result in group {
                results.append(result)
            }
            return results.sorted { $0.0 < $1.0 }.map(\.1)
        }
    }

    /// Observes a task's chat messages in real time.
    ///
    /// Uses the same parallel-resolve and stale-snapshot-drop strategy as
    /// ``observeConversations(currentUserId:)``.
    ///
    /// - Parameters:
    ///   - taskId: The task whose chat messages to observe.
    ///   - currentUserId: The signed-in user's ID, used to flag which
    ///     messages were sent by them.
    /// - Returns: An `AsyncStream` that yields the latest `[ChatMessage]`
    ///   list, in chronological order, every time the thread changes.
    ///   Yields an empty array on listener errors.
    func observeMessages(taskId: String, currentUserId: String) -> AsyncStream<[ChatMessage]> {
        DebugLogger.log("👂 observeMessages STARTED listening for taskId: \(taskId) | currentUserId: \(currentUserId)")
        return AsyncStream { continuation in
            let generationBox = SnapshotGenerationBox()

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

                    let myGeneration = generationBox.next()

                    Task {
                        let messages = await self.resolveMessages(
                            documents: documents,
                            currentUserId: currentUserId
                        )

                        guard generationBox.isCurrent(myGeneration) else {
                            DebugLogger.log("⏭️ observeMessages dropping stale snapshot for taskId: \(taskId) (generation \(myGeneration))")
                            return
                        }

                        DebugLogger.log("✅ observeMessages yielding \(messages.count) messages for taskId: \(taskId)")
                        continuation.yield(messages)
                    }
                }

            continuation.onTermination = { _ in
                listener.remove()
            }
        }
    }

    /// Resolves all message documents into `ChatMessage`s concurrently.
    ///
    /// - Parameters:
    ///   - documents: The message documents from a Firestore snapshot,
    ///     already ordered chronologically by the underlying query.
    ///   - currentUserId: The signed-in user's ID, used to flag which
    ///     messages were sent by them.
    /// - Returns: The resolved messages, restored to the original
    ///   chronological order.
    private func resolveMessages(
        documents: [QueryDocumentSnapshot],
        currentUserId: String
    ) async -> [ChatMessage] {
        await withTaskGroup(of: (Int, ChatMessage).self) { group in
            for (index, doc) in documents.enumerated() {
                group.addTask {
                    let data = doc.data()
                    let messageId = doc.documentID
                    let text = data["text"] as? String ?? ""
                    let senderId = data["senderId"] as? String ?? ""
                    let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                    let isCurrentUser = (senderId == currentUserId)
                    let reactions = data["reactions"] as? [String: String] ?? [:]

                    let senderUser = (try? await self.userRepo.fetchUserSummary(id: senderId))
                    ?? UserSummaryModel(id: senderId, displayName: "User", email: "", avatarUrl: nil, bio: "", rating: 0, totalRatings: 0, completedTasks: 0, specialties: [])

                    let message = ChatMessage(
                        id: messageId,
                        text: text,
                        time: timestamp.formatted(date: .omitted, time: .shortened),
                        sender: senderUser,
                        isCurrentUser: isCurrentUser,
                        reactions: reactions
                    )
                    return (index, message)
                }
            }

            // Collect and restore original document order (chronological,
            // since the query is ordered by `timestamp` ascending) — TaskGroup
            // completion order is not guaranteed to match input order.
            var results: [(Int, ChatMessage)] = []
            for await result in group {
                results.append(result)
            }
            return results.sorted { $0.0 < $1.0 }.map(\.1)
        }
    }

    /// Sends a message in a task's chat.
    ///
    /// Writes the message document, then bumps the recipient's unread
    /// counter and updates the chat's `lastMessage`/`lastMessageTime`, then
    /// fires a `newMessage` notification to the recipient. Notification
    /// delivery failures are logged but do not fail the send.
    ///
    /// - Parameters:
    ///   - taskId: The task whose chat to send the message in.
    ///   - messageText: The message body text.
    ///   - senderId: The sender's user ID.
    /// - Throws: A Firestore error if writing the message or updating the
    ///   chat document fails.
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

            if let recipientId {
                await createNewMessageNotification(
                    recipientId: recipientId,
                    senderId: senderId,
                    taskId: taskId,
                    messageText: messageText
                )
            }
        } catch {
            DebugLogger.log("❌ sendMessage FAILED | taskId: \(taskId) | error: \(error)")
            throw error
        }
    }

    /// Writes a `newMessage` notification so it shows up in `NotificationView`
    /// and triggers a local alert.
    ///
    /// - Parameters:
    ///   - recipientId: The user ID to notify.
    ///   - senderId: The message sender's user ID, used to look up a
    ///     display name for the notification title.
    ///   - taskId: The related task's ID.
    ///   - messageText: The message body, used as the notification body.
    private func createNewMessageNotification(
        recipientId: String,
        senderId: String,
        taskId: String,
        messageText: String
    ) async {
        let senderName = (try? await userRepo.fetchUserSummary(id: senderId))?.displayName ?? String(localized: "notification.newMessage.fallbackTitle")
        do {
            try await notificationRepo.send(
                to: recipientId,
                type: .newMessage,
                subjectText: senderName,
                messageText: messageText,
                taskId: taskId
            )
            DebugLogger.log("✅ createNewMessageNotification succeeded | recipientId: \(recipientId) | taskId: \(taskId)")
        } catch {
            DebugLogger.log("❌ createNewMessageNotification FAILED | recipientId: \(recipientId) | error: \(error)")
        }
    }

    /// Resets the current user's unread counter for a task's chat.
    ///
    /// Drives the tab badge in the UI.
    ///
    /// - Parameters:
    ///   - taskId: The task whose chat to mark as read.
    ///   - currentUserId: The signed-in user's ID.
    /// - Throws: A Firestore error if the update fails.
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

    /// Sets or clears a user's emoji reaction on a message.
    ///
    /// - Parameters:
    ///   - taskId: The task whose chat contains the message.
    ///   - messageId: The message's document ID.
    ///   - userId: The reacting user's ID.
    ///   - emoji: The emoji to set, or `nil` to remove this user's reaction.
    /// - Throws: A Firestore error if the update fails.
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

// MARK: - Snapshot Generation Tracking

/// Thread-safe monotonic counter used to detect and drop stale,
/// out-of-order snapshot resolutions.
///
/// Firestore's `addSnapshotListener` callback can fire again before a
/// previous callback's async resolution work has finished; without this, a
/// slower-resolving older snapshot could yield after a faster-resolving
/// newer one and show stale data.
private final class SnapshotGenerationBox: @unchecked Sendable {

    /// Lock guarding ``latest``.
    private let lock = NSLock()

    /// The most recently claimed generation number.
    private var latest = 0

    /// Claims this snapshot's generation number.
    ///
    /// Call synchronously inside the snapshot callback (before hopping into
    /// a `Task`).
    ///
    /// - Returns: A newly claimed, monotonically increasing generation number.
    func next() -> Int {
        lock.lock()
        defer { lock.unlock() }
        latest += 1
        return latest
    }

    /// Checks whether a given generation is still the most recent one.
    ///
    /// Call after async resolution work completes.
    ///
    /// - Parameter generation: The generation number to check, as returned
    ///   by a prior call to ``next()``.
    /// - Returns: `false` if a newer generation has been claimed in the
    ///   meantime, meaning this result is stale and should be discarded.
    func isCurrent(_ generation: Int) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return generation == latest
    }
}
