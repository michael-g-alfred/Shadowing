import Foundation
import FirebaseFirestore

/// Manages a per-user Firestore notification feed: a real-time listener plus
/// CRUD operations, including task-scoped cleanup used when a chat is torn
/// down (see ``deleteNotifications(userId:taskId:)``).
///
/// Firestore shape:
/// ```
/// users/{userId}/notifications/{notificationId}
///   userId, type, title, body, taskId?, isRead, createdAt
/// ```
final class NotificationRepository: NotificationRepositoryProtocol {

    /// Firestore database handle.
    private let db = Firestore.firestore()

    /// The currently active snapshot listener, if any.
    private var listener: ListenerRegistration?

    /// Returns the notifications subcollection reference for a given user.
    ///
    /// - Parameter userId: The user whose notifications collection to reference.
    /// - Returns: A `CollectionReference` to `users/{userId}/notifications`.
    private func collection(for userId: String) -> CollectionReference {
        db.collection("users").document(userId).collection("notifications")
    }

    /// Starts listening for real-time updates to a user's notifications.
    ///
    /// Automatically replaces any previously active listener (calls
    /// ``stopListening()`` first). Documents missing any required field are
    /// silently dropped rather than causing a decode failure.
    ///
    /// - Parameters:
    ///   - userId: The user whose notifications to observe.
    ///   - onUpdate: Called with the latest top-100 notifications
    ///     (newest first) every time the underlying data changes.
    func listenToNotifications(userId: String, onUpdate: @escaping ([NotificationModel]) -> Void) {
        stopListening()

        listener = collection(for: userId)
            .order(by: "createdAt", descending: true)
            .limit(to: 100)
            .addSnapshotListener { snapshot, error in
                if let error {
                    DebugLogger.log("NotificationRepository listen error: \(error)")
                    return
                }
                guard let documents = snapshot?.documents else {
                    onUpdate([])
                    return
                }

                let notifications: [NotificationModel] = documents.compactMap { doc in
                    let data = doc.data()
                    guard
                        let userId = data["userId"] as? String,
                        let typeRaw = data["type"] as? String,
                        let type = NotificationType(rawValue: typeRaw),
                        let isRead = data["isRead"] as? Bool,
                        let timestamp = data["createdAt"] as? Timestamp
                    else { return nil }

                    return NotificationModel(
                        id: doc.documentID,
                        userId: userId,
                        type: type,
                        subjectText: data["subjectText"] as? String,
                        messageText: data["messageText"] as? String,
                        taskId: data["taskId"] as? String,
                        isRead: isRead,
                        createdAt: timestamp.dateValue()
                    )
                }

                onUpdate(notifications)
            }
    }

    /// Detaches the currently active notification listener, if any.
    func stopListening() {
        listener?.remove()
        listener = nil
    }

    /// Creates a new notification document for a user.
    ///
    /// - Parameters:
    ///   - userId: The recipient's user ID.
    ///   - type: The notification's ``NotificationType`` — drives the
    ///     localized title/body shown on-device, via `NotificationModel`.
    ///   - subjectText: A task's title (for task-scoped types) or the
    ///     sender's display name (for `.newMessage`), interpolated into the
    ///     localized template.
    ///   - messageText: Only used for `.newMessage` — the literal message
    ///     body, stored as-is rather than localized.
    ///   - taskId: An optional related task ID, if this notification is
    ///     task-scoped (e.g. a chat message notification).
    /// - Throws: A Firestore error if the write fails.
    func send(to userId: String, type: NotificationType, subjectText: String? = nil, messageText: String? = nil, taskId: String? = nil) async throws {
        var data: [String: Any] = [
            "userId": userId,
            "type": type.rawValue,
            "isRead": false,
            "createdAt": FieldValue.serverTimestamp()
        ]
        if let subjectText {
            data["subjectText"] = subjectText
        }
        if let messageText {
            data["messageText"] = messageText
        }
        if let taskId {
            data["taskId"] = taskId
        }
        _ = try await collection(for: userId).addDocument(data: data)
    }

    /// Marks a single notification as read.
    ///
    /// - Parameters:
    ///   - userId: The notification owner's user ID.
    ///   - notificationId: The notification's document ID.
    /// - Throws: A Firestore error if the update fails.
    func markAsRead(userId: String, notificationId: String) async throws {
        try await collection(for: userId).document(notificationId).updateData(["isRead": true])
    }

    /// Marks every unread notification for a user as read, in a single batch.
    ///
    /// No-ops if the user has no unread notifications.
    ///
    /// - Parameter userId: The user whose notifications to mark as read.
    /// - Throws: A Firestore error if the query or batch commit fails.
    func markAllAsRead(userId: String) async throws {
        let snapshot = try await collection(for: userId).whereField("isRead", isEqualTo: false).getDocuments()
        guard !snapshot.documents.isEmpty else { return }
        let batch = db.batch()
        for doc in snapshot.documents {
            batch.updateData(["isRead": true], forDocument: doc.reference)
        }
        try await batch.commit()
    }

    /// Deletes a single notification.
    ///
    /// - Parameters:
    ///   - userId: The notification owner's user ID.
    ///   - notificationId: The notification's document ID.
    /// - Throws: A Firestore error if the delete fails.
    func delete(userId: String, notificationId: String) async throws {
        try await collection(for: userId).document(notificationId).delete()
    }

    /// Deletes every notification for a user, in a single batch.
    ///
    /// - Note: Firestore batches cap at 500 operations — fine for the
    ///   100-notification listener limit today, but would need chunking if
    ///   that limit ever grows past 500.
    ///
    /// - Parameter userId: The user whose notifications to delete.
    /// - Throws: A Firestore error if the query or batch commit fails.
    func deleteAll(userId: String) async throws {
        let snapshot = try await collection(for: userId).getDocuments()
        guard !snapshot.documents.isEmpty else { return }
        let batch = db.batch()
        for doc in snapshot.documents {
            batch.deleteDocument(doc.reference)
        }
        try await batch.commit()
    }

    /// Deletes a user's notifications tied to a specific task.
    ///
    /// Used when a task's chat is torn down, so stale `newMessage`
    /// notifications don't point at a chat that no longer exists.
    ///
    /// - Parameters:
    ///   - userId: The notification owner's user ID.
    ///   - taskId: The task whose related notifications should be removed.
    /// - Throws: A Firestore error if the query or batch commit fails.
    func deleteNotifications(userId: String, taskId: String) async throws {
        let snapshot = try await collection(for: userId).whereField("taskId", isEqualTo: taskId).getDocuments()
        guard !snapshot.documents.isEmpty else { return }
        let batch = db.batch()
        for doc in snapshot.documents {
            batch.deleteDocument(doc.reference)
        }
        try await batch.commit()
    }
}
