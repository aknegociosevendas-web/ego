import Foundation
import SwiftData

/// Duolingo-style streak state (docs/03, F-04). Transition math lives in the
/// Phase 1 StreakService; this is storage only.
@Model
final class Streak {
    var id: UUID = UUID()
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now

    var current: Int = 0
    var longest: Int = 0
    var lastQualifiedDay: Date?
    var freezesAvailable: Int = 0
    var freezeUsedDates: [Date]?

    init() {}
}
