import Foundation

/// Persistence boundary for focus sessions (F-01). ViewModels depend on this
/// protocol and never import SwiftData (docs/02 §2).
@MainActor
protocol FocusRepository: AnyObject {
    func save(_ session: FocusSession) throws
    func fetchAll() throws -> [FocusSession]
    func fetch(id: UUID) throws -> FocusSession?
    /// Completed sessions whose `endedAt` falls inside `interval` (coin caps, daily totals).
    func completedSessions(in interval: DateInterval) throws -> [FocusSession]
    func delete(_ session: FocusSession) throws
}
