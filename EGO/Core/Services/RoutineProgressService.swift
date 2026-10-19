import Foundation

/// Feeds the routine history (F-06): completed sessions accumulate into
/// today's `RoutineLog` for the matching block; blocks can also be checked
/// off manually from the agenda.
@MainActor
final class RoutineProgressService {
    private let routineRepository: RoutineRepository
    private let routineLogRepository: RoutineLogRepository
    private let calendar: Calendar

    init(
        routineRepository: RoutineRepository,
        routineLogRepository: RoutineLogRepository,
        calendar: Calendar = .current
    ) {
        self.routineRepository = routineRepository
        self.routineLogRepository = routineLogRepository
        self.calendar = calendar
    }

    /// Returns the updated log when the session matched one of today's blocks.
    @discardableResult
    func recordSession(_ session: FocusSession, at date: Date = .now) throws -> RoutineLog? {
        guard
            let routine = try routineRepository.activeRoutine(),
            let block = RoutineLogic.matchingBlock(
                in: routine, subject: session.subject, on: date, calendar: calendar
            )
        else { return nil }

        let log = try routineLogRepository.log(for: block, on: date)
            ?? routineLogRepository.createLog(for: block, on: date)
        log.completedMinutes += session.actualMinutes
        log.completed = log.plannedMinutes > 0 && log.completedMinutes >= log.plannedMinutes
        log.updatedAt = date
        session.routine = routine
        try routineLogRepository.save()
        return log
    }

    /// After a block edit: today's log tracks the new target/subject so the
    /// agenda stays coherent; past logs are append-only snapshots and stay
    /// untouched (F-06).
    func syncTodayLog(for block: RoutineBlock, on date: Date = .now) throws {
        guard let log = try routineLogRepository.log(for: block, on: date) else { return }
        log.plannedMinutes = block.targetMinutes
        log.subject = block.subject
        log.completed = log.plannedMinutes > 0 && log.completedMinutes >= log.plannedMinutes
        log.updatedAt = date
        try routineLogRepository.save()
    }

    /// Manual check-off from the agenda: fills the block's planned minutes.
    @discardableResult
    func checkOff(_ block: RoutineBlock, on date: Date = .now) throws -> RoutineLog {
        let log = try routineLogRepository.log(for: block, on: date)
            ?? routineLogRepository.createLog(for: block, on: date)
        log.completedMinutes = max(log.completedMinutes, log.plannedMinutes)
        log.completed = true
        log.updatedAt = date
        try routineLogRepository.save()
        return log
    }
}
