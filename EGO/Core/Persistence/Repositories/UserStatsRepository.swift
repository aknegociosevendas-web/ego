import Foundation

/// Persistence boundary for the denormalized dashboard counters.
@MainActor
protocol UserStatsRepository: AnyObject {
    /// Returns the stats record, creating it on first access.
    func fetchOrCreate() throws -> UserStats
    func save() throws
}
