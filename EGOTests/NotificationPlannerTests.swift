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

    // MARK: - Quiet hours (22h–7h)

    @Test(arguments: [
        (23, 30, 7, 0),  // inside quiet night → 7:00
        (22, 0, 7, 0),   // start is inclusive
        (6, 15, 7, 0),   // early morning still quiet
        (7, 0, 7, 0),    // end is exclusive → unchanged
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
        #expect(planned.dateComponents.hour == 7)
        #expect(planned.dateComponents.minute == 0)
    }

    // Streak-risk and comeback planning moved to
    // MotivationalNotificationPlanner (slice 7) — see its test suite.

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
