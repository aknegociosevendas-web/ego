import Foundation

/// Pure streak transition math (docs/07 §4). A day qualifies with ≥1 completed
/// focus session; freezes silently cover missed days when available.
/// `nonisolated`: pure math, opted out of the project's MainActor default.
nonisolated enum StreakLogic {
    /// Value mirror of the `Streak` model so the math stays persistence-free.
    struct State: Equatable {
        var current: Int = 0
        var longest: Int = 0
        var lastQualifiedDay: Date?
        var freezesAvailable: Int = 0
        var freezeUsedDates: [Date] = []
    }

    enum Outcome: Equatable {
        /// Second (or later) qualifying event on an already-qualified day.
        case alreadyQualifiedToday
        /// First-ever qualified day.
        case started
        /// Consecutive day, streak +1.
        case extended
        /// Missed day(s) covered by freezes, then streak +1.
        case extendedWithFreezes(consumed: Int)
        /// Missed day(s) without enough freezes → streak restarts at 1.
        case reset
    }

    static func applyQualifyingEvent(
        on date: Date,
        to state: State,
        calendar: Calendar
    ) -> (state: State, outcome: Outcome) {
        let day = calendar.startOfDay(for: date)
        var next = state

        guard let last = state.lastQualifiedDay.map({ calendar.startOfDay(for: $0) }) else {
            next.current = 1
            next.longest = max(next.longest, 1)
            next.lastQualifiedDay = day
            return (next, .started)
        }

        let gap = calendar.dateComponents([.day], from: last, to: day).day ?? 0
        // Same day (or clock moved backwards): nothing to do.
        guard gap > 0 else { return (state, .alreadyQualifiedToday) }

        let outcome: Outcome
        if gap == 1 {
            next.current += 1
            outcome = .extended
        } else {
            let missedDays = gap - 1
            if state.freezesAvailable >= missedDays {
                next.freezesAvailable -= missedDays
                for offset in 1...missedDays {
                    if let frozenDay = calendar.date(byAdding: .day, value: offset, to: last) {
                        next.freezeUsedDates.append(frozenDay)
                    }
                }
                next.current += 1
                outcome = .extendedWithFreezes(consumed: missedDays)
            } else {
                next.current = 1
                outcome = .reset
            }
        }

        next.lastQualifiedDay = day
        next.longest = max(next.longest, next.current)
        return (next, outcome)
    }
}
