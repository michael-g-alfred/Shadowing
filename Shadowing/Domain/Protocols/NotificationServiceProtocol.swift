import Foundation

protocol NotificationServiceProtocol {
    func requestAuthorization() async -> Bool
    func scheduleLocalNotification(title: String, body: String, sound: Bool, delay: TimeInterval) async throws
    func setBadgeCount(_ count: Int) async
}
