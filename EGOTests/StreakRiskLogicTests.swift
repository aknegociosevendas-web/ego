import Foundation
import Testing
@testable import EGO

struct StreakRiskLogicTests {
    let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Sao_Paulo")!
        return calendar
    }()
    let riskHour = 20

    func date(_ day: Int, hour: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 7, day: day, hour: hour))!
    }

    func isAtRisk(current: Int = 5, lastQualifiedDay: Date?, now: Date) -> Bool {
        StreakRiskLogic.isAtRisk(
            current: current,
            lastQualifiedDay: lastQualifiedDay,
            now: now,
            calendar: calendar,
            riskHour: riskHour
        )
    }

    @Test func qualifiedTodayIsNeverAtRisk() {
        #expect(!isAtRisk(lastQualifiedDay: date(10, hour: 8), now: date(10, hour: 22)))
    }

    @Test func beforeRiskHourIsNotAtRisk() {
        #expect(!isAtRisk(lastQualifiedDay: date(9, hour: 12), now: date(10, hour: 19)))
    }

    @Test func afterRiskHourWithUnqualifiedTodayIsAtRisk() {
        #expect(isAtRisk(lastQualifiedDay: date(9, hour: 12), now: date(10, hour: 20)))
        #expect(isAtRisk(lastQualifiedDay: date(9, hour: 12), now: date(10, hour: 23)))
    }

    @Test func zeroStreakIsNeverAtRisk() {
        #expect(!isAtRisk(current: 0, lastQualifiedDay: nil, now: date(10, hour: 22)))
        #expect(!isAtRisk(current: 0, lastQualifiedDay: date(9, hour: 12), now: date(10, hour: 22)))
    }

    @Test func streakAlreadyLostIsNotAtRisk() {
        // Last qualified 2+ days ago: nothing left to save tonight.
        #expect(!isAtRisk(lastQualifiedDay: date(7, hour: 12), now: date(10, hour: 22)))
    }
}
