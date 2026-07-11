import Foundation

/// Cheap shared state in the App Group container (docs/02 §6). The Live
/// Activity gets its data via ActivityKit; this snapshot feeds the Phase 4
/// Home/Lock Screen widgets (streak, today's focus, mascot mood).
@MainActor
final class AppGroupStore {
    static let groupID = "group.com.ego.EGO"

    enum Key {
        static let currentStreak = "snapshot.currentStreak"
        static let todayFocusMinutes = "snapshot.todayFocusMinutes"
    }

    private let defaults: UserDefaults?

    init() {
        defaults = UserDefaults(suiteName: Self.groupID)
    }

    func writeSnapshot(currentStreak: Int, todayFocusMinutes: Int) {
        defaults?.set(currentStreak, forKey: Key.currentStreak)
        defaults?.set(todayFocusMinutes, forKey: Key.todayFocusMinutes)
    }
}
