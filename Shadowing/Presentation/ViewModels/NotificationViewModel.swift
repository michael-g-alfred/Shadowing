import Foundation

@MainActor
@Observable
final class NotificationViewModel {
    
        // MARK: - State
    private(set) var notifications: [NotificationModel] = []
    private(set) var isLoading = false
    
    var unreadCount: Int {
        notifications.filter { !$0.isRead }.count
    }
    
        // MARK: - Dependencies
    private let notificationRepo: NotificationRepositoryProtocol
    private let notificationService: NotificationServiceProtocol
    private let authRepo: AuthRepositoryProtocol
    
    private var currentUserId: String? {
        authRepo.currentUser?.id
    }
    
        /// Tracks notification IDs we've already seen, so we only fire a local
        /// alert for genuinely new ones — not the initial snapshot on listen start.
    private var knownNotificationIds: Set<String> = []
    private var hasReceivedFirstSnapshot = false
    
    init(
        notificationRepo: NotificationRepositoryProtocol,
        notificationService: NotificationServiceProtocol,
        authRepo: AuthRepositoryProtocol
    ) {
        self.notificationRepo = notificationRepo
        self.notificationService = notificationService
        self.authRepo = authRepo
    }
    
        // MARK: - Lifecycle
    
    func startListening() {
        guard let userId = currentUserId else { return }
        isLoading = true
        knownNotificationIds = []
        hasReceivedFirstSnapshot = false
        
        notificationRepo.listenToNotifications(userId: userId) { [weak self] notifications in
            self?.handleUpdate(notifications)
        }
    }
    
    func stopListening() {
        notificationRepo.stopListening()
    }
    
        // MARK: - Incoming Notification Handling
    
    private func handleUpdate(_ incoming: [NotificationModel]) {
        defer { isLoading = false }
        
        if hasReceivedFirstSnapshot {
                // Anything unread whose ID we haven't seen before just arrived — alert for it.
            let newOnes = incoming.filter { !knownNotificationIds.contains($0.id) && !$0.isRead }
            for notification in newOnes {
                Task { [weak self] in
                    try? await self?.notificationService.scheduleLocalNotification(
                        title: notification.title,
                        body: notification.body,
                        sound: true,
                        delay: 0.1
                    )
                }
            }
        } else {
            hasReceivedFirstSnapshot = true
        }
        
        knownNotificationIds = Set(incoming.map(\.id))
        notifications = incoming
        
        Task { [weak self] in
            guard let self else { return }
            await self.notificationService.setBadgeCount(self.unreadCount)
        }
    }
    
        // MARK: - Actions
    
    func markAsRead(_ notification: NotificationModel) async {
        guard let userId = currentUserId, !notification.isRead else { return }
        do {
            try await notificationRepo.markAsRead(userId: userId, notificationId: notification.id)
        } catch {
            DebugLogger.log("markAsRead failed: \(error)")
        }
    }
    
    func markAllAsRead() async {
        guard let userId = currentUserId else { return }
        do {
            try await notificationRepo.markAllAsRead(userId: userId)
        } catch {
            DebugLogger.log("markAllAsRead failed: \(error)")
        }
    }
    
    func delete(_ notification: NotificationModel) async {
        guard let userId = currentUserId else { return }
        do {
            try await notificationRepo.delete(userId: userId, notificationId: notification.id)
        } catch {
            DebugLogger.log("delete notification failed: \(error)")
        }
    }
    
    func deleteAll() async {
        guard let userId = currentUserId else { return }
        do {
            try await notificationRepo.deleteAll(userId: userId)
        } catch {
            DebugLogger.log("deleteAll notifications failed: \(error)")
        }
    }
}
