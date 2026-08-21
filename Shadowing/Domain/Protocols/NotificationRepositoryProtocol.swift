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
        ///
        /// `title`/`body` aren't passed in directly — `NotificationModel` derives
        /// them as localized text from `type`, so every device shows them in its
        /// own language. Instead, pass whatever dynamic text that template needs:
        /// - `subjectText`: a task's title for task-scoped types, or the sender's
        ///   display name for `.newMessage`.
        /// - `messageText`: only for `.newMessage`, the literal message body
        ///   (not localized — it's chat content, not template text).
    func send(to userId: String, type: NotificationType, subjectText: String?, messageText: String?, taskId: String?) async throws
    
    func markAsRead(userId: String, notificationId: String) async throws
    func markAllAsRead(userId: String) async throws
    func delete(userId: String, notificationId: String) async throws
    func deleteAll(userId: String) async throws
    
        /// Deletes this user's notifications tied to a specific task — used when a
        /// task's chat is torn down, so stale `newMessage` notifications don't point
        /// at a chat that no longer exists.
    func deleteNotifications(userId: String, taskId: String) async throws
}
