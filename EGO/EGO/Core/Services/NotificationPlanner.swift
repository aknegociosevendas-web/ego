import Foundation

/// A notification ready to hand to the scheduler. When `afterInterval` is
/// set the scheduler uses a time-interval trigger instead of the calendar one.
nonisolated struct PlannedNotification: Equatable, Sendable {
    let identifier: String
    let title: String
    let body: String
    var dateComponents = DateComponents()
    var repeats = false
    var afterInterval: TimeInterval?
    /// Carried into UNNotificationContent.userInfo (deep link: phraseId/category).
    var userInfo: [String: String] = [:]
}

/// Pure scheduling math for the session reminder (F-09). Streak-risk and
/// comeback planning moved to `MotivationalNotificationPlanner` (slice 7).
nonisolated enum NotificationPlanner {
    /// Moves a fire time out of the quiet window to its end (docs F-09).
    static func shiftedOutOfQuietHours(
        hour: Int,
        minute: Int,
        config: NotificationConfig
    ) -> (hour: Int, minute: Int) {
        let inQuietHours = hour >= config.quietHoursStart || hour < config.quietHoursEnd
        return inQuietHours ? (config.quietHoursEnd, 0) : (hour, minute)
    }

    /// Daily repeating session reminder.
    static func sessionReminder(
        hour: Int,
        minute: Int,
        title: String,
        body: String,
        config: NotificationConfig
    ) -> PlannedNotification {
        let time = shiftedOutOfQuietHours(hour: hour, minute: minute, config: config)
        var components = DateComponents()
        components.hour = time.hour
        components.minute = time.minute
        return PlannedNotification(
            identifier: NotificationConfig.Identifier.sessionReminder,
            title: title,
            body: body,
            dateComponents: components,
            repeats: true
        )
    }

    /// Deterministic daily rotation through a phrase list. Day counting via
    /// the local start-of-day (`ordinality` proved flaky under load).
    static func phraseIndex(count: Int, on date: Date, calendar: Calendar) -> Int {
        guard count > 0 else { return 0 }
        let day = Int((calendar.startOfDay(for: date)
            .timeIntervalSinceReferenceDate / 86_400).rounded(.down))
        return ((day % count) + count) % count
    }
}
