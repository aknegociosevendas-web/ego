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
    func deleteBlock(_ block: RoutineBlock) throws
    func save() throws
}
