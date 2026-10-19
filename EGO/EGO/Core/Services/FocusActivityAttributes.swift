import ActivityKit
import Foundation

/// Live Activity contract, shared by the app (requests/updates) and the
/// EGOWidgets extension (renders). Keep it small: everything dynamic goes in
/// `ContentState`; ActivityKit pushes updates, no App Group needed here.
nonisolated struct FocusActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        /// "focus" / "shortBreak" / "longBreak" (PomodoroViewModel.Phase key).
        var phase: String
        var endDate: Date
        var isPaused: Bool
        /// Seconds left when paused (countdown text freezes).
        var pausedRemaining: TimeInterval?
    }

    var subject: String?
    var streakCount: Int
}
