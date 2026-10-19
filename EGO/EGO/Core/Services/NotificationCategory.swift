import Foundation

/// The eight motivational-notification categories (slice 7). Raw values match
/// both the `category` field in `motivational-phrases.json` and the
/// `NotificationTemplate.category` column for new rows.
nonisolated enum NotificationCategory: String, Codable, CaseIterable, Sendable {
    case comeback
    case streakAtRisk
    case morningBoost
    case afternoonFocus
    case eveningWindDown
    case milestone
    case sessionReminder
    case generic

    /// UserDefaults key for the per-category enable toggle (Settings E).
    var settingsKey: String { "notification.category.\(rawValue).enabled" }
}
