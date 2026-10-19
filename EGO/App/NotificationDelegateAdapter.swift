import Foundation
import UserNotifications

/// Bridges UNUserNotificationCenter callbacks into the app (slice 7): a tap
/// on a motivational notification carries `phraseId`/`category` in userInfo
/// and lands on the card presenter. Extensible seam for future non-
/// motivational deep links. Retained by the DIContainer.
final class NotificationDelegateAdapter: NSObject, UNUserNotificationCenterDelegate {
    private let onMotivationalTap: @MainActor (_ phraseId: String?, _ categoryRaw: String) -> Void

    init(onMotivationalTap: @escaping @MainActor (_ phraseId: String?, _ categoryRaw: String) -> Void) {
        self.onMotivationalTap = onMotivationalTap
    }

    func install() {
        UNUserNotificationCenter.current().delegate = self
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let info = response.notification.request.content.userInfo
        let phraseId = info["phraseId"] as? String
        let categoryRaw = info["category"] as? String
        if let categoryRaw {
            let handler = onMotivationalTap
            Task { @MainActor in
                handler(phraseId, categoryRaw)
            }
        }
        completionHandler()
    }

    /// Foreground deliveries still show a banner (the Settings test button
    /// relies on it).
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
