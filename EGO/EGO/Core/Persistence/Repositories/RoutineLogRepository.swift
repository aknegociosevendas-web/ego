import Foundation

/// Persistence boundary for the append-only routine history (F-06).
@MainActor
protocol RoutineLogRepository: AnyObject {
    /// The row for `block` on `day`'s calendar day, if any.
    func log(for block: RoutineBlock, on day: Date) throws -> RoutineLog?
    @discardableResult
    func createLog(for block: RoutineBlock, on day: Date) throws -> RoutineLog
    func logs(in interval: DateInterval) throws -> [RoutineLog]
    /// 6-month rolling window: drops rows older than `date`.
    func prune(olderThan date: Date) throws
    func save() throws
}
