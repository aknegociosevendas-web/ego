import Foundation

/// Persistence boundary for routines (F-05).
@MainActor
protocol RoutineRepository: AnyObject {
    func activeRoutine() throws -> Routine?
    func create(name: String?, templateKey: String?, startDate: Date) throws -> Routine
    @discardableResult
    func addBlock(
        to routine: Routine,
        weekday: Int,
        subject: String,
        targetMinutes: Int,
        targetSessions: Int,
        order: Int
    ) throws -> RoutineBlock
    /// In-place edit preserving the block's identity and its `RoutineLog`
    /// history (F-05 — never delete+recreate).
    func updateBlock(
        _ block: RoutineBlock,
        weekday: Int,
        subject: String,
        targetMinutes: Int,
        targetSessions: Int
    ) throws
    func deleteBlock(_ block: RoutineBlock) throws
    func save() throws
}
