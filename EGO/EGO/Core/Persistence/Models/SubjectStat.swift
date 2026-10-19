import Foundation
import SwiftData

/// Per-subject denormalized rollup (docs/03), updated transactionally when a
/// session completes so the dashboard stays O(1). Question counters are
/// populated in Phase 3 with the question bank.
@Model
final class SubjectStat {
    var id: UUID = UUID()
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now

    var subject: String?
    var focusMinutes: Int = 0
    var questionsSolved: Int = 0
    var questionsCorrect: Int = 0
    /// To-one, no inverse — keeps the CloudKit schema trivial.
    var stats: UserStats?

    init(subject: String? = nil) {
        self.subject = subject
    }
}
