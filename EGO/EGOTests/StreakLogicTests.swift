import Foundation
import Testing
@testable import EGO

struct StreakLogicTests {
    let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Sao_Paulo")!
        return calendar
    }()

    func day(_ year: Int, _ month: Int, _ dayOfMonth: Int, hour: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: dayOfMonth, hour: hour))!
    }

    @Test func firstQualifyingDayStartsStreak() {
        let (state, outcome) = StreakLogic.applyQualifyingEvent(
            on: day(2026, 7, 10), to: StreakLogic.State(), calendar: calendar
        )
        #expect(outcome == .started)
        #expect(state.current == 1)
        #expect(state.longest == 1)
        #expect(state.lastQualifiedDay == calendar.startOfDay(for: day(2026, 7, 10)))
    }

    @Test func secondEventOnSameDayIsIdempotent() {
        let (first, _) = StreakLogic.applyQualifyingEvent(
            on: day(2026, 7, 10, hour: 8), to: StreakLogic.State(), calendar: calendar
        )
        let (second, outcome) = StreakLogic.applyQualifyingEvent(
            on: day(2026, 7, 10, hour: 22), to: first, calendar: calendar
        )
        #expect(outcome == .alreadyQualifiedToday)
        #expect(second == first)
    }

    @Test func consecutiveDayExtendsStreak() {
        let (first, _) = StreakLogic.applyQualifyingEvent(
            on: day(2026, 7, 10), to: StreakLogic.State(), calendar: calendar
        )
        let (second, outcome) = StreakLogic.applyQualifyingEvent(
            on: day(2026, 7, 11), to: first, calendar: calendar
        )
        #expect(outcome == .extended)
        #expect(second.current == 2)
        #expect(second.longest == 2)
    }

    @Test func missedDayWithFreezePreservesStreak() {
        var state = StreakLogic.State(current: 5, longest: 5, freezesAvailable: 2)
        state.lastQualifiedDay = day(2026, 7, 10)
        // Skips July 11 entirely, qualifies again on the 12th.
        let (next, outcome) = StreakLogic.applyQualifyingEvent(
            on: day(2026, 7, 12), to: state, calendar: calendar
        )
        #expect(outcome == .extendedWithFreezes(consumed: 1))
        #expect(next.current == 6)
        #expect(next.freezesAvailable == 1)
        #expect(next.freezeUsedDates.count == 1)
        #expect(calendar.isDate(next.freezeUsedDates[0], inSameDayAs: day(2026, 7, 11)))
    }

    @Test func missedDayWithoutFreezeResets() {
        var state = StreakLogic.State(current: 12, longest: 12, freezesAvailable: 0)
        state.lastQualifiedDay = day(2026, 7, 10)
        let (next, outcome) = StreakLogic.applyQualifyingEvent(
            on: day(2026, 7, 12), to: state, calendar: calendar
        )
        #expect(outcome == .reset)
        #expect(next.current == 1)
        #expect(next.longest == 12)
    }

    @Test func multiDayGapConsumesOneFreezePerMissedDay() {
        var state = StreakLogic.State(current: 3, longest: 3, freezesAvailable: 3)
        state.lastQualifiedDay = day(2026, 7, 10)
        // Missed 11, 12 and 13; qualifies on the 14th.
        let (next, outcome) = StreakLogic.applyQualifyingEvent(
            on: day(2026, 7, 14), to: state, calendar: calendar
        )
        #expect(outcome == .extendedWithFreezes(consumed: 3))
        #expect(next.current == 4)
        #expect(next.freezesAvailable == 0)
        #expect(next.freezeUsedDates.count == 3)
    }

    @Test func multiDayGapWithTooFewFreezesResets() {
        var state = StreakLogic.State(current: 3, longest: 3, freezesAvailable: 1)
        state.lastQualifiedDay = day(2026, 7, 10)
        let (next, outcome) = StreakLogic.applyQualifyingEvent(
            on: day(2026, 7, 14), to: state, calendar: calendar
        )
        #expect(outcome == .reset)
        #expect(next.current == 1)
        // Freezes are not partially burned on a reset.
        #expect(next.freezesAvailable == 1)
    }

    @Test func longestNeverDecreases() {
        var state = StreakLogic.State(current: 2, longest: 30)
        state.lastQualifiedDay = day(2026, 7, 10)
        let (next, _) = StreakLogic.applyQualifyingEvent(
            on: day(2026, 7, 11), to: state, calendar: calendar
        )
        #expect(next.current == 3)
        #expect(next.longest == 30)
    }
}
