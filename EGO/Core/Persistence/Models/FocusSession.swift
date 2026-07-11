import Foundation
import SwiftData

/// One Pomodoro/focus interval (docs/03).
@Model
final class FocusSession {
    /// Known values for `type`.
    enum SessionType: String {
        case focus
        case shortBreak = "short"
        case longBreak = "long"
    }

    var id: UUID = UUID()
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now

    var startedAt: Date?
    var endedAt: Date?
    var plannedMinutes: Int = 25
    var actualMinutes: Int = 0
    /// Raw value of `SessionType`; stored as String for CloudKit friendliness.
    var type: String = SessionType.focus.rawValue
    var completed: Bool = false
    var abandoned: Bool = false
    var subject: String?

    /// Inverses live on `TopicGoal.sessions` / `Routine.sessions`.
    var goal: TopicGoal?
    var routine: Routine?

    init(
        startedAt: Date? = nil,
        plannedMinutes: Int = 25,
        type: SessionType = .focus,
        subject: String? = nil
    ) {
        self.startedAt = startedAt
        self.plannedMinutes = plannedMinutes
        self.type = type.rawValue
        self.subject = subject
    }
}
