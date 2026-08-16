import Foundation
import FirebaseFirestore

final class NotificationRepository: NotificationRepositoryProtocol {
    
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    private func collection(for userId: String) -> CollectionReference {
        db.collection("users").document(userId).collection("notifications")
    }
    
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
                        let title = data["title"] as? String,
                        let body = data["body"] as? String,
                        let isRead = data["isRead"] as? Bool,
                        let timestamp = data["createdAt"] as? Timestamp
                    else { return nil }
                    
                    return NotificationModel(
                        id: doc.documentID,
                        userId: userId,
                        type: type,
                        title: title,
                        body: body,
                        taskId: data["taskId"] as? String,
                        isRead: isRead,
                        createdAt: timestamp.dateValue()
                    )
                }
                
                onUpdate(notifications)
            }
    }
    
    func stopListening() {
        listener?.remove()
        listener = nil
    }
    
    func send(to userId: String, type: NotificationType, title: String, body: String, taskId: String? = nil) async throws {
        var data: [String: Any] = [
            "userId": userId,
            "type": type.rawValue,
            "title": title,
            "body": body,
            "isRead": false,
            "createdAt": FieldValue.serverTimestamp()
        ]
        if let taskId {
            data["taskId"] = taskId
        }
        _ = try await collection(for: userId).addDocument(data: data)
    }
    
    func markAsRead(userId: String, notificationId: String) async throws {
        try await collection(for: userId).document(notificationId).updateData(["isRead": true])
    }
    
    func markAllAsRead(userId: String) async throws {
        let snapshot = try await collection(for: userId).whereField("isRead", isEqualTo: false).getDocuments()
        guard !snapshot.documents.isEmpty else { return }
        let batch = db.batch()
        for doc in snapshot.documents {
            batch.updateData(["isRead": true], forDocument: doc.reference)
        }
        try await batch.commit()
    }
    
    func delete(userId: String, notificationId: String) async throws {
        try await collection(for: userId).document(notificationId).delete()
    }
    
        /// Note: Firestore batches cap at 500 ops, same constraint as `markAllAsRead`
        /// above — fine for the 100-notification listener limit, but would need
        /// chunking if that limit ever grows past 500.
    func deleteAll(userId: String) async throws {
        let snapshot = try await collection(for: userId).getDocuments()
        guard !snapshot.documents.isEmpty else { return }
        let batch = db.batch()
        for doc in snapshot.documents {
            batch.deleteDocument(doc.reference)
        }
        try await batch.commit()
    }
    
        /// Deletes this user's notifications tied to a specific task — used when a
        /// task's chat is torn down, so stale `newMessage` notifications don't point
        /// at a chat that no longer exists.
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
