import Foundation
import SwiftData

/// One planned block in the weekly routine (docs/03, F-05).
/// `weekday` follows `Calendar` convention: 1 = Sunday … 7 = Saturday.
@Model
final class RoutineBlock {
    var id: UUID = UUID()
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now

    var weekday: Int?
    var subject: String?
    var targetMinutes: Int = 0
    var targetSessions: Int = 0
    var order: Int = 0

    var routine: Routine?
    @Relationship(inverse: \RoutineLog.block)
    var logs: [RoutineLog]?

    init(weekday: Int? = nil, subject: String? = nil, targetMinutes: Int = 0, targetSessions: Int = 0, order: Int = 0) {
        self.weekday = weekday
        self.subject = subject
        self.targetMinutes = targetMinutes
        self.targetSessions = targetSessions
        self.order = order
    }
}
