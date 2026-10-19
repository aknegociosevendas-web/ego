import Foundation
import SwiftData

/// The user's identity, preferences and gamification wallet (docs/03).
/// CloudKit-safe: every attribute defaulted or optional, no unique constraints.
@Model
final class UserProfile {
    var id: UUID = UUID()
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now

    var displayName: String?
    /// e.g. "ENEM 2026".
    var examTarget: String?
    var examDate: Date?
    var dailyGoalMinutes: Int = 25
    var mascotId: String?
    var mascotName: String?
    var xp: Int = 0
    var level: Int = 1
    var coins: Int = 0
    var appearanceTheme: String?

    init(
        displayName: String? = nil,
        examTarget: String? = nil,
        examDate: Date? = nil,
        dailyGoalMinutes: Int = 25
    ) {
        self.displayName = displayName
        self.examTarget = examTarget
        self.examDate = examDate
        self.dailyGoalMinutes = dailyGoalMinutes
    }
}
