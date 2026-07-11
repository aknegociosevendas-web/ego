import Foundation
import Testing
@testable import EGO

struct NotificationPlannerTests {
    let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Sao_Paulo")!
        return calendar
    }()
    let config = NotificationConfig.standard

    func date(_ day: Int, hour: Int, minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(
            year: 2026, month: 7, day: day, hour: hour, minute: minute
        ))!
    }

    // MARK: - Quiet hours (22h–8h)

    @Test(arguments: [
        (23, 30, 8, 0),  // inside quiet night → 8:00
        (22, 0, 8, 0),   // start is inclusive
        (6, 15, 8, 0),   // early morning still quiet
        (8, 0, 8, 0),    // end is exclusive → unchanged
        (12, 45, 12, 45),
        (21, 59, 21, 59),
    ])
    func quietHoursShift(hour: Int, minute: Int, expectedHour: Int, expectedMinute: Int) {
        let shifted = NotificationPlanner.shiftedOutOfQuietHours(
            hour: hour, minute: minute, config: config
        )
        #expect(shifted.hour == expectedHour)
        #expect(shifted.minute == expectedMinute)
    }

    // MARK: - Session reminder

    @Test func sessionReminderRepeatsDailyAtRequestedTime() {
        let planned = NotificationPlanner.sessionReminder(
            hour: 18, minute: 30, title: "T", body: "B", config: config
        )
        #expect(planned.repeats)
        #expect(planned.identifier == NotificationConfig.Identifier.sessionReminder)
        #expect(planned.dateComponents.hour == 18)
        #expect(planned.dateComponents.minute == 30)
        #expect(planned.dateComponents.day == nil) // daily, not date-bound
    }

    @Test func sessionReminderInsideQuietHoursShiftsToMorning() {
        let planned = NotificationPlanner.sessionReminder(
            hour: 23, minute: 0, title: "T", body: "B", config: config
        )
        #expect(planned.dateComponents.hour == 8)
        #expect(planned.dateComponents.minute == 0)
    }

    // MARK: - Streak risk

    func riskPlan(lastDay: Int?, now: Date, current: Int = 5) -> PlannedNotification? {
        NotificationPlanner.streakRisk(
            streakCurrent: current,
            lastQualifiedDay: lastDay.map { date($0, hour: 12) },
            now: now,
            calendar: calendar,
            riskHour: 20,
            title: "T",
            body: "B"
        )
    }

    @Test func streakRiskPlannedBeforeRiskHour() {
        let planned = riskPlan(lastDay: 9, now: date(10, hour: 10))
        #expect(planned != nil)
        #expect(planned?.repeats == false)
        #expect(planned?.dateComponents.day == 10)
        #expect(planned?.dateComponents.hour == 20)
    }

    @Test func streakRiskNotPlannedAfterRiskHour() {
        #expect(riskPlan(lastDay: 9, now: date(10, hour: 20)) == nil)
        #expect(riskPlan(lastDay: 9, now: date(10, hour: 22)) == nil)
    }

    @Test func streakRiskNotPlannedWhenTodayQualified() {
        #expect(riskPlan(lastDay: 10, now: date(10, hour: 10)) == nil)
    }

    @Test func streakRiskNotPlannedWithoutStreak() {
        #expect(riskPlan(lastDay: nil, now: date(10, hour: 10)) == nil)
        #expect(riskPlan(lastDay: 9, now: date(10, hour: 10), current: 0) == nil)
    }

    @Test func streakRiskNotPlannedWhenStreakAlreadyLost() {
        #expect(riskPlan(lastDay: 7, now: date(10, hour: 10)) == nil)
    }

    // MARK: - Comeback

    @Test func comebackPlannedThreeDaysAfterLastActivity() {
        let planned = NotificationPlanner.comeback(
            lastActiveDay: date(10, hour: 14),
            now: date(10, hour: 15),
            calendar: calendar,
            title: "T",
            body: "B",
            config: config
        )
        #expect(planned != nil)
        #expect(planned?.dateComponents.day == 13)
        #expect(planned?.dateComponents.hour == 18)
        #expect(planned?.repeats == false)
    }

    @Test func comebackNotPlannedWhenFireDateHasPassed() {
        let planned = NotificationPlanner.comeback(
            lastActiveDay: date(5, hour: 14),
            now: date(10, hour: 15),
            calendar: calendar,
            title: "T",
            body: "B",
            config: config
        )
        #expect(planned == nil)
    }

    @Test func comebackNotPlannedWithoutActivity() {
        let planned = NotificationPlanner.comeback(
            lastActiveDay: nil,
            now: date(10, hour: 15),
            calendar: calendar,
            title: "T",
            body: "B",
            config: config
        )
        #expect(planned == nil)
    }

    // MARK: - Phrase rotation

    @Test func phraseRotationIsDeterministicPerDay() {
        let morning = NotificationPlanner.phraseIndex(count: 4, on: date(10, hour: 8), calendar: calendar)
        let evening = NotificationPlanner.phraseIndex(count: 4, on: date(10, hour: 21), calendar: calendar)
        let nextDay = NotificationPlanner.phraseIndex(count: 4, on: date(11, hour: 8), calendar: calendar)

        #expect(morning == evening)
        #expect(nextDay == (morning + 1) % 4)
        #expect((0..<4).contains(morning))
    }

    @Test func phraseIndexHandlesEmptyList() {
        #expect(NotificationPlanner.phraseIndex(count: 0, on: date(10, hour: 8), calendar: calendar) == 0)
    }
}
