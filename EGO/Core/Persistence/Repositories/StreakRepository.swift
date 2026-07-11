import Foundation

/// Persistence boundary for the streak record (F-04).
@MainActor
protocol StreakRepository: AnyObject {
    /// Returns the streak, creating it on first access.
    func fetchOrCreate() throws -> Streak
    func save() throws
}
