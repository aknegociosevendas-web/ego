import Foundation
import Testing
@testable import EGO

@MainActor
struct RoutineLogicTests {
    let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Sao_Paulo")!
        return calendar
    }()

    // July 13, 2026 is a Monday (weekday 2).
    func monday(hour: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 7, day: 13, hour: hour))!
    }

    func makeRoutine() -> Routine {
        let routine = Routine(name: "Teste", startDate: monday())
        let math = RoutineBlock(weekday: 2, subject: "Matemática", targetMinutes: 50, order: 1)
        let essay = RoutineBlock(weekday: 2, subject: "Redação", targetMinutes: 50, order: 0)
        let tuesday = RoutineBlock(weekday: 3, subject: "Português", targetMinutes: 50, order: 0)
        routine.blocks = [math, essay, tuesday]
        return routine
    }

    @Test func blocksFilterByWeekdayAndSortByOrder() {
        let routine = makeRoutine()
        let blocks = RoutineLogic.blocks(of: routine, on: monday(), calendar: calendar)
        #expect(blocks.count == 2)
        #expect(blocks[0].subject == "Redação")
        #expect(blocks[1].subject == "Matemática")
    }

    @Test func matchingBlockRequiresSubjectAndWeekday() {
        let routine = makeRoutine()
        let match = RoutineLogic.matchingBlock(
            in: routine, subject: "Matemática", on: monday(), calendar: calendar
        )
        #expect(match?.subject == "Matemática")

        // Tuesday subject doesn't match on Monday.
        #expect(RoutineLogic.matchingBlock(
            in: routine, subject: "Português", on: monday(), calendar: calendar
        ) == nil)
        #expect(RoutineLogic.matchingBlock(
            in: routine, subject: nil, on: monday(), calendar: calendar
        ) == nil)
        #expect(RoutineLogic.matchingBlock(
            in: routine, subject: "Física", on: monday(), calendar: calendar
        ) == nil)
    }
}
