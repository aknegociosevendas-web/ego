import Foundation
import Testing
@testable import EGO

struct MotivationalNotificationPlannerTests {
    let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Sao_Paulo")!
        return calendar
    }()

    func date(_ day: Int, hour: Int, minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(
            year: 2026, month: 7, day: day, hour: hour, minute: minute
        ))!
    }

    /// Baseline: day 10 at 10:00, everything enabled, no history.
    func context(
        now: Date? = nil,
        lastActive: Date? = nil,
        lastQualified: Date? = nil,
        streak: Int = 0
    ) -> MotivationalNotificationPlanner.Context {
        var ctx = MotivationalNotificationPlanner.Context(now: now ?? date(10, hour: 10))
        ctx.calendar = calendar
        ctx.lastActiveDay = lastActive
        ctx.lastQualifiedDay = lastQualified
        ctx.streakCurrent = streak
        return ctx
    }

    func slots(
        _ ctx: MotivationalNotificationPlanner.Context
    ) -> [NotificationCategory: [Date]] {
        Dictionary(
            grouping: MotivationalNotificationPlanner.plan(ctx), by: \.category
        ).mapValues { $0.map(\.fireDate) }
    }

    // MARK: - Daypart slots

    @Test func daypartSlotsFillTheDayUpToTheRateLimit() {
        let planned = slots(context())
        // Before 15h: afternoon (15:00) and evening (20:30) are today's two;
        // morning already passed → tomorrow, but tomorrow's quota also caps.
        #expect(planned[.afternoonFocus]?.first == date(10, hour: 15))
        #expect(planned[.eveningWindDown]?.first == date(10, hour: 20, minute: 30))
    }

    @Test func rateLimitKeepsAtMostTwoPerDay() {
        let all = MotivationalNotificationPlanner.plan(context())
        let byDay = Dictionary(grouping: all) { calendar.startOfDay(for: $0.fireDate) }
        #expect(byDay.values.allSatisfy { $0.count <= 2 })
    }

    @Test func afternoonSkipsTodayAfterACompletedSession() {
        var ctx = context()
        ctx.hasCompletedSessionToday = true
        let planned = slots(ctx)
        #expect(planned[.afternoonFocus]?.first == date(11, hour: 15))
    }

    @Test func disabledCategoryIsNeverPlanned() {
        var ctx = context()
        ctx.enabled.remove(.eveningWindDown)
        #expect(slots(ctx)[.eveningWindDown] == nil)
    }

    // MARK: - Streak at risk

    @Test func streakAtRiskPlansTwoShotsTonight() {
        let ctx = context(lastQualified: date(9, hour: 12), streak: 4)
        let risk = slots(ctx)[.streakAtRisk]
        #expect(risk == [date(10, hour: 20), date(10, hour: 21, minute: 30)])
    }

    @Test func streakAtRiskConsumesTheDailyQuota() {
        let ctx = context(lastQualified: date(9, hour: 12), streak: 4)
        let planned = slots(ctx)
        // Both shots survive; the 20:30 wind-down loses its slot today.
        #expect(planned[.streakAtRisk]?.count == 2)
        #expect(!(planned[.eveningWindDown] ?? []).contains { d in
            calendar.isDate(d, inSameDayAs: date(10, hour: 12))
        })
    }

    @Test func streakAtRiskNotPlannedWhenTodayQualified() {
        let ctx = context(lastQualified: date(10, hour: 9), streak: 4)
        #expect(slots(ctx)[.streakAtRisk] == nil)
    }

    @Test func streakAtRiskShotsInsideQuietHoursAreDropped() {
        var ctx = context(lastQualified: date(9, hour: 12), streak: 4)
        ctx.quietStartMinutes = 21 * 60  // quiet from 21:00
        let risk = slots(ctx)[.streakAtRisk]
        // 21:30 falls inside the window and is dropped, not shifted.
        #expect(risk == [date(10, hour: 20)])
    }

    // MARK: - Comeback

    @Test func comebackPlannedAfterIdleDaysAtUsualHour() {
        var ctx = context(lastActive: date(8, hour: 14))
        ctx.usualStartHour = 16
        let comeback = slots(ctx)[.comeback]
        #expect(comeback?.first == date(10, hour: 16))
    }

    @Test func comebackFallsBackToNineteenWithoutHistory() {
        let ctx = context(lastActive: date(8, hour: 14))
        #expect(slots(ctx)[.comeback]?.first == date(10, hour: 19))
    }

    @Test func comebackMovesToTomorrowWhenHourPassed() {
        var ctx = context(now: date(10, hour: 20), lastActive: date(8, hour: 14))
        ctx.usualStartHour = 16
        #expect(slots(ctx)[.comeback]?.first == date(11, hour: 16))
    }

    @Test func comebackNotPlannedWhenActiveToday() {
        let ctx = context(lastActive: date(10, hour: 8))
        #expect(slots(ctx)[.comeback] == nil)
    }

    @Test func comebackNotPlannedAfterFourIdleDays() {
        let ctx = context(lastActive: date(5, hour: 8))
        #expect(slots(ctx)[.comeback] == nil)
    }

    @Test func streakAtRiskBeatsComebackOnTheSameDay() {
        var ctx = context(
            lastActive: date(8, hour: 14),
            lastQualified: date(9, hour: 12),
            streak: 4
        )
        ctx.usualStartHour = 16
        let planned = slots(ctx)
        #expect(planned[.streakAtRisk]?.count == 2)
        #expect(!(planned[.comeback] ?? []).contains { d in
            calendar.isDate(d, inSameDayAs: date(10, hour: 12))
        })
    }

    // MARK: - Quiet hours + suppression

    @Test func eveningInsideQuietHoursShiftsToNextMorning() {
        var ctx = context()
        ctx.quietStartMinutes = 20 * 60  // quiet from 20:00
        let evening = slots(ctx)[.eveningWindDown]
        // 20:30 sits in the wrapping window → exits tomorrow at 07:00.
        #expect(evening?.first == date(11, hour: 7))
    }

    @Test func suppressionWindowDropsEarlyCandidates() {
        var ctx = context()
        ctx.suppressedUntil = date(10, hour: 16)
        let planned = slots(ctx)
        // Today's 15:00 afternoon is inside the suppression window.
        #expect(!(planned[.afternoonFocus] ?? []).contains(date(10, hour: 15)))
    }
}
