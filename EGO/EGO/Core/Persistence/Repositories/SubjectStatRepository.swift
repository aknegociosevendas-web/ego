import Foundation

/// Persistence boundary for per-subject rollups.
@MainActor
protocol SubjectStatRepository: AnyObject {
    func fetchAll() throws -> [SubjectStat]
    /// Returns the rollup for `subject`, creating (and attaching) it on first use.
    func fetchOrCreate(subject: String, attachedTo stats: UserStats?) throws -> SubjectStat
    func save() throws
}
