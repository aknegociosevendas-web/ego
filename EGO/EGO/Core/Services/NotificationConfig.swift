import Foundation

/// Tunable notification behavior (F-03/F-09, slice 7). Quiet hours defaults
/// live here; the user's actual window comes from `NotificationSettingsStore`
/// (Settings › Notificações).
nonisolated struct NotificationConfig: Sendable, Equatable {
    /// Quiet window defaults: no notifications from `quietHoursStart`
    /// (inclusive) until `quietHoursEnd` (exclusive); planned fires shift to
    /// the end.
    var quietHoursStart: Int = 22
    var quietHoursEnd: Int = 7
    /// Default daily session reminder hour, created on opt-in.
    var defaultReminderHour: Int = 18

    // Motivational slots (slice 7).
    var morningHour: Int = 7
    var morningMinute: Int = 30
    var afternoonHour: Int = 15
    var eveningHour: Int = 20
    var eveningMinute: Int = 30
    var streakRiskFirstHour: Int = 20
    var streakRiskFirstMinute: Int = 0
    var streakRiskSecondHour: Int = 21
    var streakRiskSecondMinute: Int = 30
    /// Comeback fires at the user's usual study hour; this is the fallback
    /// when there's no session history.
    var comebackFallbackHour: Int = 19
    /// Rate limit: motivational fires per calendar day (milestone and
    /// sessionReminder never count).
    var maxMotivationalPerDay: Int = 2
    /// Anti-spam: opening the app within `antiSpamOpenWindow` of a delivered
    /// motivational suppresses new ones for `antiSpamSuppression`.
    var antiSpamOpenWindow: TimeInterval = 15 * 60
    var antiSpamSuppression: TimeInterval = 4 * 3_600

    static let standard = NotificationConfig()

    /// Fixed identifiers so re-planning replaces instead of stacking.
    enum Identifier {
        static let sessionReminder = "ego.reminder.session"
        static let softFocusWarning = "ego.softfocus.warning"

        /// Prefix shared by every motivational one-shot (delivery detection).
        static let motivationalPrefix = "ego.motivational."
        static let motivationalMorning = "ego.motivational.morning"
        static let motivationalAfternoon = "ego.motivational.afternoon"
        static let motivationalEvening = "ego.motivational.evening"
        static let motivationalStreakRisk1 = "ego.motivational.streakRisk.1"
        static let motivationalStreakRisk2 = "ego.motivational.streakRisk.2"
        static let motivationalComeback = "ego.motivational.comeback"
        static let motivationalTest = "ego.motivational.test"

        /// Pre-slice-7 one-shots, cancelled on migration.
        static let legacyStreakRisk = "ego.streak.risk"
        static let legacyComeback = "ego.comeback"

        static let allMotivational = [
            motivationalMorning, motivationalAfternoon, motivationalEvening,
            motivationalStreakRisk1, motivationalStreakRisk2, motivationalComeback,
        ]
    }
}
