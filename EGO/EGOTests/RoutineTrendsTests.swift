import Foundation
import Testing
@testable import EGO

@MainActor
struct RoutineTrendsTests {
    let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Sao_Paulo")!
        return calendar
    }()

    func date(_ day: Int, hour: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 7, day: day, hour: hour))!
    }

    func completedLog(day: Int, minutes: Int = 50) -> RoutineLog {
        let log = RoutineLog(date: calendar.startOfDay(for: date(day)), plannedMinutes: minutes)
        log.completedMinutes = minutes
        log.completed = true
        return log
    }

    @Test func consistencyCountsPlannedOccurrencesInWindow() {
        // One block every Monday; routine started long ago.
        let routine = Routine(startDate: date(1))
        routine.blocks = [RoutineBlock(weekday: 2, subject: "Matemática", targetMinutes: 50)]

        // Window: Jul 4 … Jul 31 (28 days) has 4 Mondays (6, 13, 20, 27).
        let result = RoutineTrends.consistency(
            routine: routine, logs: [completedLog(day: 6), completedLog(day: 13)],
            upTo: date(31), calendar: calendar
        )
        #expect(result.plannedCount == 4)
        #expect(result.completedCount == 2)
        #expect(abs(result.percentage - 0.5) < 0.0001)
    }

    @Test func consistencyClampsToRoutineStart() {
        // Routine started Jul 20: only Mondays Jul 20 and 27 count.
        let routine = Routine(startDate: date(20))
        routine.blocks = [RoutineBlock(weekday: 2, subject: "Matemática", targetMinutes: 50)]

        let result = RoutineTrends.consistency(
            routine: routine, logs: [], upTo: date(31), calendar: calendar
        )
        #expect(result.plannedCount == 2)
        #expect(result.completedCount == 0)
        #expect(result.percentage == 0)
    }

    @Test func emptyRoutineHasZeroConsistency() {
        let routine = Routine(startDate: date(1))
        let result = RoutineTrends.consistency(
            routine: routine, logs: [], upTo: date(31), calendar: calendar
        )
        #expect(result.plannedCount == 0)
        #expect(result.percentage == 0)
    }

    @Test func minutesByWeekdaySumsCompletedMinutes() {
        // Jul 13 and 20 are Mondays (weekday 2); Jul 14 is a Tuesday.
        let logs = [
            completedLog(day: 13, minutes: 50),
            completedLog(day: 20, minutes: 30),
            completedLog(day: 14, minutes: 25),
        ]
        let minutes = RoutineTrends.minutesByWeekday(logs: logs, calendar: calendar)
        #expect(minutes[2] == 80)
        #expect(minutes[3] == 25)
        #expect(minutes[4] == nil)
    }
}
