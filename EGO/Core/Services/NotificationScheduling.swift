import Foundation
import UserNotifications

/// Thin seam over UNUserNotificationCenter so scheduling is testable
/// (the real center can't be exercised from unit tests).
@MainActor
protocol NotificationScheduling: AnyObject {
    func requestAuthorization() async -> Bool
    func isAuthorized() async -> Bool
    func schedule(_ notification: PlannedNotification) async
    func cancel(identifiers: [String])
}

@MainActor
final class UserNotificationScheduler: NotificationScheduling {
    private let center = UNUserNotificationCenter.current()

    func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    func isAuthorized() async -> Bool {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral: return true
        default: return false
        }
    }

    func schedule(_ notification: PlannedNotification) async {
        let content = UNMutableNotificationContent()
        content.title = notification.title
        content.body = notification.body
        content.sound = .default
        let trigger: UNNotificationTrigger = if let interval = notification.afterInterval {
            UNTimeIntervalNotificationTrigger(timeInterval: max(1, interval), repeats: false)
        } else {
            UNCalendarNotificationTrigger(
                dateMatching: notification.dateComponents,
                repeats: notification.repeats
            )
        }
        let request = UNNotificationRequest(
            identifier: notification.identifier,
            content: content,
            trigger: trigger
        )
        try? await center.add(request)
    }

    func cancel(identifiers: [String]) {
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
}
