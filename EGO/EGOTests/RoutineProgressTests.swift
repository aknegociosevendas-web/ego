import Foundation
import Testing
@testable import EGO

@MainActor
struct RoutineProgressTests {
    func makeContext() throws -> DIContainer {
        let container = try PersistenceController.makeInMemoryContainer()
        return DIContainer(modelContainer: container)
    }

    /// Active routine with one block for today's weekday.
    func seedRoutine(_ di: DIContainer, subject: String = "Matemática", minutes: Int = 50) throws -> Routine {
        let routine = try di.routineRepository.create(name: "Teste", templateKey: nil, startDate: .now)
        let weekday = Calendar.current.component(.weekday, from: .now)
        try di.routineRepository.addBlock(
            to: routine, weekday: weekday, subject: subject,
            targetMinutes: minutes, targetSessions: 2, order: 0
        )
        return routine
    }

    @Test func completedSessionAccumulatesIntoTodayLog() throws {
        let di = try makeContext()
        let routine = try seedRoutine(di)

        let first = FocusSession(plannedMinutes: 25, subject: "Matemática")
        first.actualMinutes = 25
        try di.sessionCompletionService.completeSession(first)

        let today = Calendar.current.startOfDay(for: .now)
        let logs = try di.routineLogRepository.logs(
            in: DateInterval(start: today, duration: 86_400)
        )
        #expect(logs.count == 1)
        #expect(logs[0].completedMinutes == 25)
        #expect(logs[0].plannedMinutes == 50)
        #expect(!logs[0].completed)
        #expect(first.routine === routine)

        // Second session reaches the block target → completed, same row.
        let second = FocusSession(plannedMinutes: 25, subject: "Matemática")
        second.actualMinutes = 25
        try di.sessionCompletionService.completeSession(second)

        let updated = try di.routineLogRepository.logs(
            in: DateInterval(start: today, duration: 86_400)
        )
        #expect(updated.count == 1)
        #expect(updated[0].completedMinutes == 50)
        #expect(updated[0].completed)
    }

    @Test func sessionWithoutMatchingBlockLeavesNoLog() throws {
        let di = try makeContext()
        _ = try seedRoutine(di, subject: "Matemática")

        let session = FocusSession(plannedMinutes: 25, subject: "Inglês")
        session.actualMinutes = 25
        try di.sessionCompletionService.completeSession(session)

        let today = Calendar.current.startOfDay(for: .now)
        #expect(try di.routineLogRepository.logs(
            in: DateInterval(start: today, duration: 86_400)
        ).isEmpty)
        #expect(session.routine == nil)
    }

    @Test func manualCheckOffFillsPlannedMinutes() throws {
        let di = try makeContext()
        let routine = try seedRoutine(di)
        let block = (routine.blocks ?? [])[0]

        let log = try di.routineProgressService.checkOff(block)

        #expect(log.completed)
        #expect(log.completedMinutes == 50)
    }

    @Test func updateBlockPreservesIdentityAndHistory() throws {
        let di = try makeContext()
        let routine = try seedRoutine(di, minutes: 50)
        let block = (routine.blocks ?? [])[0]
        let originalID = block.id
        let calendar = Calendar.current

        // Yesterday's snapshot + today's partial progress.
        let yesterday = calendar.date(byAdding: .day, value: -1, to: .now)!
        let pastLog = try di.routineLogRepository.createLog(for: block, on: yesterday)
        let todayLog = try di.routineLogRepository.createLog(for: block, on: .now)
        todayLog.completedMinutes = 25
        try di.routineLogRepository.save()

        try di.routineRepository.updateBlock(
            block, weekday: block.weekday ?? 2, subject: "Física",
            targetMinutes: 25, targetSessions: 1
        )
        try di.routineProgressService.syncTodayLog(for: block)

        // Same row, history intact.
        #expect(block.id == originalID)
        #expect(block.logs?.count == 2)

        // Today resyncs (25/25 → completed); yesterday keeps its snapshot.
        #expect(todayLog.plannedMinutes == 25)
        #expect(todayLog.subject == "Física")
        #expect(todayLog.completed)
        #expect(pastLog.plannedMinutes == 50)
        #expect(pastLog.subject == "Matemática")
    }

    @Test func raisingTargetReopensTodayLog() throws {
        let di = try makeContext()
        let routine = try seedRoutine(di, minutes: 25)
        let block = (routine.blocks ?? [])[0]

        // Check-off completes today's log at 25 min.
        let log = try di.routineProgressService.checkOff(block)
        #expect(log.completed)

        try di.routineRepository.updateBlock(
            block, weekday: block.weekday ?? 2, subject: "Matemática",
            targetMinutes: 60, targetSessions: 2
        )
        try di.routineProgressService.syncTodayLog(for: block)

        #expect(log.plannedMinutes == 60)
        #expect(!log.completed)
    }

    @Test func pruneDropsRowsOlderThanSixMonths() throws {
        let di = try makeContext()
        let routine = try seedRoutine(di)
        let block = (routine.blocks ?? [])[0]
        let calendar = Calendar.current

        let old = try di.routineLogRepository.createLog(
            for: block, on: calendar.date(byAdding: .day, value: -200, to: .now)!
        )
        _ = old
        try di.routineLogRepository.createLog(for: block, on: .now)

        try di.routineLogRepository.prune(
            olderThan: calendar.date(byAdding: .day, value: -180, to: .now)!
        )

        let window = DateInterval(
            start: calendar.date(byAdding: .day, value: -365, to: .now)!,
            end: .now
        )
        let remaining = try di.routineLogRepository.logs(in: window)
        #expect(remaining.count == 1)
        #expect(calendar.isDateInToday(remaining[0].date ?? .distantPast))
    }
}
