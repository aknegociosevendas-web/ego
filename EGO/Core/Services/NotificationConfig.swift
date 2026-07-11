import Foundation

/// Tunable notification behavior (F-03/F-09). Quiet hours and times are
/// code constants until the Settings UI (F-18) exposes them.
nonisolated struct NotificationConfig: Sendable, Equatable {
    /// Quiet window: no notifications from `quietHoursStart` (inclusive)
    /// until `quietHoursEnd` (exclusive); planned fires shift to the end.
    var quietHoursStart: Int = 22
    var quietHoursEnd: Int = 8
    /// Default daily session reminder hour, created on opt-in.
    var defaultReminderHour: Int = 18
    /// Days of inactivity before the comeback nudge fires.
    var comebackAfterDays: Int = 3

    static let standard = NotificationConfig()

    /// Fixed identifiers so re-planning replaces instead of stacking.
    enum Identifier {
        static let sessionReminder = "ego.reminder.session"
        static let streakRisk = "ego.streak.risk"
        static let comeback = "ego.comeback"
        static let softFocusWarning = "ego.softfocus.warning"
    }
}
