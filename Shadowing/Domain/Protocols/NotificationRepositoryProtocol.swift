import Foundation

protocol NotificationRepositoryProtocol {
        /// Starts a realtime listener on the current user's notifications collection.
        /// Call `stopListening()` to tear it down (e.g. on sign out).
    func listenToNotifications(userId: String, onUpdate: @escaping ([NotificationModel]) -> Void)
    func stopListening()
    
        /// Creates a new notification document for `userId`. Fire-and-forget from
        /// callers' perspective — failures should be swallowed with `try?` at the
        /// call site rather than surfaced as a user-facing error, since a failed
        /// notification shouldn't roll back the action that triggered it.
    func send(to userId: String, type: NotificationType, title: String, body: String, taskId: String?) async throws
    
    func markAsRead(userId: String, notificationId: String) async throws
    func markAllAsRead(userId: String) async throws
    func delete(userId: String, notificationId: String) async throws
    func deleteAll(userId: String) async throws
}
