import Foundation
import SwiftData

/// Append-only routine history (docs/03, F-06): one row per block × day,
/// accumulated while the day runs, never rewritten afterwards. Rows older
/// than 6 months are pruned.
@Model
final class RoutineLog {
    var id: UUID = UUID()
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now

    /// Start of the day this row belongs to.
    var date: Date?
    var subject: String?
    var plannedMinutes: Int = 0
    var completedMinutes: Int = 0
    var completed: Bool = false

    var block: RoutineBlock?

    init(date: Date? = nil, subject: String? = nil, plannedMinutes: Int = 0) {
        self.date = date
        self.subject = subject
        self.plannedMinutes = plannedMinutes
    }
}
