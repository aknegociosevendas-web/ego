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
    /// Delivery dates of already-shown notifications whose identifier starts
    /// with `prefix` (anti-spam detection, slice 7).
    func deliveredDates(identifierPrefix: String) async -> [Date]
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
        if !notification.userInfo.isEmpty {
            content.userInfo = notification.userInfo
        }
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

    func deliveredDates(identifierPrefix: String) async -> [Date] {
        await center.deliveredNotifications()
            .filter { $0.request.identifier.hasPrefix(identifierPrefix) }
            .map(\.date)
    }
}
