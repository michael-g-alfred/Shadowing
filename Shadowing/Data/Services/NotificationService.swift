import Foundation
import UserNotifications

final class NotificationService: NSObject, NotificationServiceProtocol {
    
    private let center = UNUserNotificationCenter.current()
    
    override init() {
        super.init()
        center.delegate = self
    }
    
        // MARK: - Authorization
    
    @discardableResult
    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            DebugLogger.log("NotificationService authorization failed: \(error)")
            return false
        }
    }
    
        // MARK: - Scheduling
    
    func scheduleLocalNotification(
        title: String,
        body: String,
        sound: Bool = true,
        delay: TimeInterval = 0.1
    ) async throws {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = sound ? .default : nil
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(delay, 0.1), repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        try await center.add(request)
    }
    
        // MARK: - Badge
    
    func setBadgeCount(_ count: Int) async {
        do {
            try await center.setBadgeCount(count)
        } catch {
            DebugLogger.log("NotificationService setBadgeCount failed: \(error)")
        }
    }
}

    // MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {
    
        /// Called when a notification arrives while the app is in the foreground.
        /// Without this, iOS silently swallows the banner and sound.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
}
