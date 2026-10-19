import Foundation

/// User-facing notification preferences (slice 7): quiet hours, per-category
/// toggles, and the anti-spam suppression window. Backed by UserDefaults with
/// the same keys `NotificationSettingsView` binds via `@AppStorage`, so the
/// scheduler always reads what the screen wrote.
@MainActor
final class NotificationSettingsStore {
    enum Keys {
        static let quietStartMinutes = "notification.quietStartMinutes"
        static let quietEndMinutes = "notification.quietEndMinutes"
        static let suppressedUntil = "notification.suppressedUntil"
        static let lastMotivationalDeliveredAt = "lastMotivationalDeliveredAt"
    }

    nonisolated static let defaultQuietStartMinutes = 22 * 60
    nonisolated static let defaultQuietEndMinutes = 7 * 60

    /// Internal so tests can flip toggles directly.
    let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var quietStartMinutes: Int {
        defaults.object(forKey: Keys.quietStartMinutes) as? Int
            ?? Self.defaultQuietStartMinutes
    }

    var quietEndMinutes: Int {
        defaults.object(forKey: Keys.quietEndMinutes) as? Int
            ?? Self.defaultQuietEndMinutes
    }

    func isEnabled(_ category: NotificationCategory) -> Bool {
        defaults.object(forKey: category.settingsKey) as? Bool ?? true
    }

    var enabledCategories: Set<NotificationCategory> {
        Set(NotificationCategory.allCases.filter(isEnabled))
    }

    /// Anti-spam: opening the app within 15 minutes of a delivered
    /// motivational suppresses new ones for 4 hours.
    var suppressedUntil: Date? {
        get {
            let t = defaults.double(forKey: Keys.suppressedUntil)
            return t > 0 ? Date(timeIntervalSinceReferenceDate: t) : nil
        }
        set {
            defaults.set(
                newValue?.timeIntervalSinceReferenceDate ?? 0,
                forKey: Keys.suppressedUntil
            )
        }
    }

    var lastMotivationalDeliveredAt: Date? {
        get {
            let t = defaults.double(forKey: Keys.lastMotivationalDeliveredAt)
            return t > 0 ? Date(timeIntervalSinceReferenceDate: t) : nil
        }
        set {
            defaults.set(
                newValue?.timeIntervalSinceReferenceDate ?? 0,
                forKey: Keys.lastMotivationalDeliveredAt
            )
        }
    }
}
