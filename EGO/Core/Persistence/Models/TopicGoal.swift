import Foundation
import SwiftData

/// Per-subject/topic study goal (docs/03, F-10). Progress is fed by
/// completed focus sessions (questions/essays arrive in Phase 3).
@Model
final class TopicGoal {
    var id: UUID = UUID()
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now

    var subject: String?
    var topic: String?
    var targetHours: Double?
    var targetQuestions: Int?
    var targetEssays: Int?
    var deadline: Date?
    var progressMinutes: Int = 0
    var progressQuestions: Int = 0
    var completed: Bool = false

    @Relationship(inverse: \FocusSession.goal)
    var sessions: [FocusSession]?

    init(
        subject: String? = nil,
        topic: String? = nil,
        targetHours: Double? = nil,
        targetQuestions: Int? = nil,
        deadline: Date? = nil
    ) {
        self.subject = subject
        self.topic = topic
        self.targetHours = targetHours
        self.targetQuestions = targetQuestions
        self.deadline = deadline
    }
}
