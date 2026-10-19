import ActivityKit
import Foundation

/// Seam over ActivityKit so the ViewModel is testable (activities can't run
/// in unit tests) — same pattern as `NotificationScheduling`.
@MainActor
protocol FocusActivityManaging: AnyObject {
    func startActivity(phase: String, endDate: Date, subject: String?, streakCount: Int)
    func updateActivity(phase: String, endDate: Date, isPaused: Bool, pausedRemaining: TimeInterval?)
    func endActivity()
}

/// One live activity at a time, mirroring the running Pomodoro (F-16).
@MainActor
final class FocusActivityController: FocusActivityManaging {
    private var activity: Activity<FocusActivityAttributes>?

    func startActivity(phase: String, endDate: Date, subject: String?, streakCount: Int) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            #if DEBUG
            print("⚠️ Live Activities disabled for this app")
            #endif
            return
        }
        endActivity()
        let attributes = FocusActivityAttributes(subject: subject, streakCount: streakCount)
        let state = FocusActivityAttributes.ContentState(
            phase: phase, endDate: endDate, isPaused: false, pausedRemaining: nil
        )
        do {
            activity = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: endDate)
            )
        } catch {
            #if DEBUG
            print("⚠️ Live Activity request failed: \(error)")
            #endif
        }
    }

    func updateActivity(phase: String, endDate: Date, isPaused: Bool, pausedRemaining: TimeInterval?) {
        guard let activity else { return }
        let state = FocusActivityAttributes.ContentState(
            phase: phase, endDate: endDate, isPaused: isPaused, pausedRemaining: pausedRemaining
        )
        Task {
            await activity.update(.init(state: state, staleDate: endDate))
        }
    }

    func endActivity() {
        guard let activity else { return }
        self.activity = nil
        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }
}
