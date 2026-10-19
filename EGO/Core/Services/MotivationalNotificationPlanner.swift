import Foundation

/// Pure planning math for the slice-7 motivational triggers. Consumes a state
/// snapshot, returns the one-shot slots to schedule — no UNUserNotificationCenter,
/// no models, fully unit-testable. The service replans on every launch /
/// backgrounding, so everything is a one-shot (recurrence emerges from
/// replanning; cancellations stay deterministic).
nonisolated enum MotivationalNotificationPlanner {
    struct Context {
        var now: Date
        var calendar: Calendar = .current
        /// Quiet window in minutes-since-midnight (wraps past midnight).
        var quietStartMinutes: Int = NotificationSettingsStore.defaultQuietStartMinutes
        var quietEndMinutes: Int = NotificationSettingsStore.defaultQuietEndMinutes
        var enabled: Set<NotificationCategory> = Set(NotificationCategory.allCases)
        /// Anti-spam window: no motivational fires before this instant.
        var suppressedUntil: Date?
        var lastActiveDay: Date?
        var hasCompletedSessionToday = false
        var streakCurrent = 0
        var lastQualifiedDay: Date?
        /// Mean start hour of recent sessions (comeback heuristic); nil → 19h.
        var usualStartHour: Int?
        var config: NotificationConfig = .standard
    }

    struct Slot: Equatable {
        let category: NotificationCategory
        let identifier: String
        let fireDate: Date
    }

    /// Rate limit: max 2 motivational fires per calendar day, priority
    /// streakAtRisk > comeback > morning > afternoon > evening.
    private static let priority: [NotificationCategory: Int] = [
        .streakAtRisk: 0, .comeback: 1, .morningBoost: 2,
        .afternoonFocus: 3, .eveningWindDown: 4,
    ]

    static func plan(_ ctx: Context) -> [Slot] {
        var candidates: [Slot] = []
        candidates += streakAtRiskSlots(ctx)
        candidates += comebackSlot(ctx)
        candidates += daypartSlot(
            ctx, category: .morningBoost,
            identifier: NotificationConfig.Identifier.motivationalMorning,
            hour: ctx.config.morningHour, minute: ctx.config.morningMinute,
            skipToday: false
        )
        candidates += daypartSlot(
            ctx, category: .afternoonFocus,
            identifier: NotificationConfig.Identifier.motivationalAfternoon,
            hour: ctx.config.afternoonHour, minute: 0,
            skipToday: ctx.hasCompletedSessionToday
        )
        candidates += daypartSlot(
            ctx, category: .eveningWindDown,
            identifier: NotificationConfig.Identifier.motivationalEvening,
            hour: ctx.config.eveningHour, minute: ctx.config.eveningMinute,
            skipToday: false
        )

        // Anti-spam suppression window.
        if let until = ctx.suppressedUntil {
            candidates.removeAll { $0.fireDate <= until }
        }

        // streakAtRisk owns its day: a same-day comeback loses outright.
        let riskDays = Set(candidates
            .filter { $0.category == .streakAtRisk }
            .map { ctx.calendar.startOfDay(for: $0.fireDate) })
        candidates.removeAll {
            $0.category == .comeback
                && riskDays.contains(ctx.calendar.startOfDay(for: $0.fireDate))
        }

        // Rate limit per calendar day.
        var kept: [Slot] = []
        let byDay = Dictionary(grouping: candidates) {
            ctx.calendar.startOfDay(for: $0.fireDate)
        }
        for (_, slots) in byDay {
            let ranked = slots.sorted {
                let l = (priority[$0.category] ?? 9, $0.fireDate)
                let r = (priority[$1.category] ?? 9, $1.fireDate)
                return l < r
            }
            kept += ranked.prefix(ctx.config.maxMotivationalPerDay)
        }
        return kept.sorted { $0.fireDate < $1.fireDate }
    }

    // MARK: - Candidates

    /// Streak alive (yesterday qualified), today not qualified yet: two shots
    /// tonight. Shots inside quiet hours are dropped, not shifted — a risk
    /// nudge past midnight can't help anymore.
    private static func streakAtRiskSlots(_ ctx: Context) -> [Slot] {
        guard ctx.enabled.contains(.streakAtRisk),
              ctx.streakCurrent > 0,
              let last = ctx.lastQualifiedDay,
              let yesterday = ctx.calendar.date(
                  byAdding: .day, value: -1, to: ctx.calendar.startOfDay(for: ctx.now)
              ),
              ctx.calendar.isDate(last, inSameDayAs: yesterday)
        else { return [] }

        let shots = [
            (NotificationConfig.Identifier.motivationalStreakRisk1,
             ctx.config.streakRiskFirstHour, ctx.config.streakRiskFirstMinute),
            (NotificationConfig.Identifier.motivationalStreakRisk2,
             ctx.config.streakRiskSecondHour, ctx.config.streakRiskSecondMinute),
        ]
        return shots.compactMap { identifier, hour, minute in
            guard let fire = ctx.calendar.date(
                bySettingHour: hour, minute: minute, second: 0, of: ctx.now
            ), fire > ctx.now, !isInQuietHours(fire, ctx) else { return nil }
            return Slot(category: .streakAtRisk, identifier: identifier, fireDate: fire)
        }
    }

    /// 1–3 idle days: one shot at the user's usual study hour (fallback 19h),
    /// today if still ahead, otherwise tomorrow.
    private static func comebackSlot(_ ctx: Context) -> [Slot] {
        guard ctx.enabled.contains(.comeback), let lastActive = ctx.lastActiveDay else { return [] }
        let idleDays = ctx.calendar.dateComponents(
            [.day],
            from: ctx.calendar.startOfDay(for: lastActive),
            to: ctx.calendar.startOfDay(for: ctx.now)
        ).day ?? 0
        guard (1...3).contains(idleDays) else { return [] }

        let hour = ctx.usualStartHour ?? ctx.config.comebackFallbackHour
        guard var fire = ctx.calendar.date(
            bySettingHour: hour, minute: 0, second: 0, of: ctx.now
        ) else { return [] }
        if fire <= ctx.now {
            guard let next = ctx.calendar.date(byAdding: .day, value: 1, to: fire) else { return [] }
            fire = next
        }
        guard let shifted = shiftedOutOfQuietHours(fire, ctx) else { return [] }
        return [Slot(
            category: .comeback,
            identifier: NotificationConfig.Identifier.motivationalComeback,
            fireDate: shifted
        )]
    }

    /// Next occurrence of a fixed daily slot (today if still ahead).
    private static func daypartSlot(
        _ ctx: Context,
        category: NotificationCategory,
        identifier: String,
        hour: Int,
        minute: Int,
        skipToday: Bool
    ) -> [Slot] {
        guard ctx.enabled.contains(category) else { return [] }
        guard var fire = ctx.calendar.date(
            bySettingHour: hour, minute: minute, second: 0, of: ctx.now
        ) else { return [] }
        if fire <= ctx.now || skipToday {
            guard let next = ctx.calendar.date(byAdding: .day, value: 1, to: fire) else { return [] }
            fire = next
        }
        guard let shifted = shiftedOutOfQuietHours(fire, ctx) else { return [] }
        return [Slot(category: category, identifier: identifier, fireDate: shifted)]
    }

    // MARK: - Quiet hours (minutes-since-midnight, window may wrap midnight)

    static func isInQuietHours(_ date: Date, _ ctx: Context) -> Bool {
        let comps = ctx.calendar.dateComponents([.hour, .minute], from: date)
        let m = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
        let start = ctx.quietStartMinutes
        let end = ctx.quietEndMinutes
        if start == end { return false }
        return start < end ? (m >= start && m < end) : (m >= start || m < end)
    }

    /// Shifts a fire date sitting inside the quiet window to the window's
    /// end; nil when the shifted date is already in the past.
    static func shiftedOutOfQuietHours(_ date: Date, _ ctx: Context) -> Date? {
        guard isInQuietHours(date, ctx) else { return date }
        let comps = ctx.calendar.dateComponents([.hour, .minute], from: date)
        let m = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
        // Wrapping window, evening side: the exit is tomorrow morning.
        let needsDayHop = ctx.quietStartMinutes > ctx.quietEndMinutes
            && m >= ctx.quietStartMinutes
        guard var shifted = ctx.calendar.date(
            bySettingHour: ctx.quietEndMinutes / 60,
            minute: ctx.quietEndMinutes % 60,
            second: 0,
            of: date
        ) else { return nil }
        if needsDayHop {
            guard let next = ctx.calendar.date(byAdding: .day, value: 1, to: shifted) else { return nil }
            shifted = next
        }
        return shifted > ctx.now ? shifted : nil
    }
}
