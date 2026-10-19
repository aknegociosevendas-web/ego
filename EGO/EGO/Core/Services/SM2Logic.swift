import Foundation

/// Classic SM-2 spaced repetition (docs/08 §1). Pure and exhaustively tested.
nonisolated enum SM2Logic {
    struct State: Equatable {
        var easeFactor: Double = 2.5
        var interval: Int = 0
        var repetitions: Int = 0
    }

    /// One review with quality grade 0…5 (clamped).
    /// - EF' = max(1.3, EF + 0.1 − (5−q)(0.08 + (5−q)·0.02))
    /// - q < 3 → repetitions reset, review again tomorrow.
    /// - q ≥ 3 → intervals 1, 6, then round(previous · EF').
    static func review(_ state: State, grade: Int) -> State {
        let q = Double(min(5, max(0, grade)))
        var next = state
        next.easeFactor = max(1.3, state.easeFactor + 0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))

        if grade < 3 {
            next.repetitions = 0
            next.interval = 1
        } else {
            next.repetitions = state.repetitions + 1
            switch next.repetitions {
            case 1: next.interval = 1
            case 2: next.interval = 6
            default: next.interval = max(1, Int((Double(state.interval) * next.easeFactor).rounded()))
            }
        }
        return next
    }

    /// Next due date from a review on `date`.
    static func dueDate(after state: State, reviewedOn date: Date, calendar: Calendar) -> Date {
        calendar.date(
            byAdding: .day,
            value: max(1, state.interval),
            to: calendar.startOfDay(for: date)
        ) ?? date
    }

    /// Auto-grade for in-app answers (no extra grading UI): wrong = 2,
    /// slow correct = 4, quick correct = 5. `slowThreshold` in seconds.
    static func gradeForAnswer(correct: Bool, timeSpent: Int, slowThreshold: Int = 60) -> Int {
        guard correct else { return 2 }
        return timeSpent > slowThreshold ? 4 : 5
    }
}
