import Foundation
import SwiftData

/// Denormalized counters for O(1) dashboards (docs/03). Updated transactionally
/// when a session/attempt/essay completes. Per-subject rollups (`SubjectStat`)
/// arrive in Phase 1 with the stats feature.
@Model
final class UserStats {
    var id: UUID = UUID()
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now

    var totalFocusMinutes: Int = 0
    var totalSessions: Int = 0
    var questionsSolved: Int = 0
    var questionsCorrect: Int = 0
    var essaysFinished: Int = 0
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var lastActiveDay: Date?

    /// Inverse of `SubjectStat.stats` — CloudKit requires every relationship
    /// to have an (optional) inverse.
    @Relationship(inverse: \SubjectStat.stats)
    var subjectStats: [SubjectStat]?

    init() {}
}
