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
}

/// Pure scheduling math for the three F-03 triggers. No UNUserNotificationCenter,
/// no models — fully unit-testable.
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

    /// One-shot "streak at risk" for today at `riskHour`. Only planned while
    /// it can still help: streak alive (yesterday qualified), today not
    /// qualified yet, and the risk hour hasn't passed.
    static func streakRisk(
        streakCurrent: Int,
        lastQualifiedDay: Date?,
        now: Date,
        calendar: Calendar,
        riskHour: Int,
        title: String,
        body: String
    ) -> PlannedNotification? {
        guard streakCurrent > 0, let last = lastQualifiedDay else { return nil }
        guard let yesterday = calendar.date(
            byAdding: .day,
            value: -1,
            to: calendar.startOfDay(for: now)
        ) else { return nil }
        guard calendar.isDate(last, inSameDayAs: yesterday) else { return nil }
        guard calendar.component(.hour, from: now) < riskHour else { return nil }

        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = riskHour
        components.minute = 0
        return PlannedNotification(
            identifier: NotificationConfig.Identifier.streakRisk,
            title: title,
            body: body,
            dateComponents: components,
            repeats: false
        )
    }

    /// One-shot comeback nudge `comebackAfterDays` after the last activity.
    static func comeback(
        lastActiveDay: Date?,
        now: Date,
        calendar: Calendar,
        title: String,
        body: String,
        config: NotificationConfig
    ) -> PlannedNotification? {
        guard let lastActiveDay else { return nil }
        let time = shiftedOutOfQuietHours(
            hour: config.defaultReminderHour, minute: 0, config: config
        )
        guard
            let targetDay = calendar.date(
                byAdding: .day,
                value: config.comebackAfterDays,
                to: calendar.startOfDay(for: lastActiveDay)
            ),
            let fireDate = calendar.date(
                bySettingHour: time.hour, minute: time.minute, second: 0, of: targetDay
            ),
            fireDate > now
        else { return nil }

        return PlannedNotification(
            identifier: NotificationConfig.Identifier.comeback,
            title: title,
            body: body,
            dateComponents: calendar.dateComponents(
                [.year, .month, .day, .hour, .minute], from: fireDate
            ),
            repeats: false
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
