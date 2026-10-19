import Foundation
import Testing
@testable import EGO

@MainActor
struct StatsAggregatorTests {
    let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Sao_Paulo")!
        return calendar
    }()

    func date(_ day: Int, hour: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 7, day: day, hour: hour))!
    }

    func completedSession(minutes: Int, endedAt: Date) -> FocusSession {
        let session = FocusSession(plannedMinutes: minutes)
        session.actualMinutes = minutes
        session.completed = true
        session.endedAt = endedAt
        return session
    }

    @Test func producesSevenBucketsWithZeros() {
        let result = StatsAggregator.dailyMinutes(from: [], endingOn: date(10), calendar: calendar)
        #expect(result.count == 7)
        #expect(result.allSatisfy { $0.minutes == 0 })
        #expect(result.first?.day == calendar.startOfDay(for: date(4)))
        #expect(result.last?.day == calendar.startOfDay(for: date(10)))
    }

    @Test func sumsMinutesPerDay() {
        let sessions = [
            completedSession(minutes: 25, endedAt: date(10, hour: 9)),
            completedSession(minutes: 50, endedAt: date(10, hour: 21)),
            completedSession(minutes: 30, endedAt: date(8)),
        ]
        let result = StatsAggregator.dailyMinutes(from: sessions, endingOn: date(10), calendar: calendar)
        #expect(result.last?.minutes == 75)
        #expect(result[4].minutes == 30) // July 8 = index 4 of 4…10
        #expect(result[5].minutes == 0)
    }

    @Test func excludesSessionsOutsideTheWindow() {
        let sessions = [completedSession(minutes: 40, endedAt: date(2))]
        let result = StatsAggregator.dailyMinutes(from: sessions, endingOn: date(10), calendar: calendar)
        #expect(result.allSatisfy { $0.minutes == 0 })
    }

    @Test func excludesAbandonedSessions() {
        let abandoned = FocusSession(plannedMinutes: 25)
        abandoned.actualMinutes = 10
        abandoned.abandoned = true
        abandoned.endedAt = date(10)
        let result = StatsAggregator.dailyMinutes(from: [abandoned], endingOn: date(10), calendar: calendar)
        #expect(result.last?.minutes == 0)
    }
}
