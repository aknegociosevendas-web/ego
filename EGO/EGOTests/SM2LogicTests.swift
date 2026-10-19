import Foundation
import Testing
@testable import EGO

struct SM2LogicTests {
    let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Sao_Paulo")!
        return calendar
    }()

    // MARK: - Ease factor formula: EF' = EF + 0.1 − (5−q)(0.08 + (5−q)·0.02)

    @Test(arguments: [
        (5, 2.6),   // +0.1
        (4, 2.5),   // ±0
        (3, 2.36),  // −0.14
        (2, 2.18),  // −0.32
        (1, 1.96),  // −0.54
        (0, 1.7),   // −0.8
    ])
    func easeFactorUpdates(grade: Int, expected: Double) {
        let next = SM2Logic.review(SM2Logic.State(), grade: grade)
        #expect(abs(next.easeFactor - expected) < 0.0001)
    }

    @Test func easeFactorClampsAtFloor() {
        var state = SM2Logic.State(easeFactor: 1.35, interval: 1, repetitions: 1)
        state = SM2Logic.review(state, grade: 0) // −0.8 would go below 1.3
        #expect(state.easeFactor == 1.3)
    }

    @Test func gradeIsClampedToValidRange() {
        let high = SM2Logic.review(SM2Logic.State(), grade: 9)
        #expect(abs(high.easeFactor - 2.6) < 0.0001) // treated as 5
        let low = SM2Logic.review(SM2Logic.State(), grade: -3)
        #expect(abs(low.easeFactor - 1.7) < 0.0001) // treated as 0
        #expect(low.repetitions == 0)
    }

    // MARK: - Interval progression

    @Test func failingGradeResetsRepetitionsAndReviewsTomorrow() {
        var state = SM2Logic.State(easeFactor: 2.5, interval: 15, repetitions: 3)
        state = SM2Logic.review(state, grade: 2)
        #expect(state.repetitions == 0)
        #expect(state.interval == 1)
    }

    @Test func successfulSequenceFollowsOneSixThenEFMultiples() {
        // Three "good" (4) reviews: EF stays 2.5, intervals 1 → 6 → 15.
        var state = SM2Logic.State()
        state = SM2Logic.review(state, grade: 4)
        #expect(state.repetitions == 1)
        #expect(state.interval == 1)

        state = SM2Logic.review(state, grade: 4)
        #expect(state.repetitions == 2)
        #expect(state.interval == 6)

        state = SM2Logic.review(state, grade: 4)
        #expect(state.repetitions == 3)
        #expect(state.interval == 15) // round(6 × 2.5)
        #expect(abs(state.easeFactor - 2.5) < 0.0001)
    }

    @Test func easySequenceGrowsFasterThanGood() {
        // Three "easy" (5) reviews: EF 2.5→2.6→2.7→2.8, third interval round(6×2.8)=17.
        var state = SM2Logic.State()
        state = SM2Logic.review(state, grade: 5)
        state = SM2Logic.review(state, grade: 5)
        state = SM2Logic.review(state, grade: 5)
        #expect(state.interval == 17)
        #expect(abs(state.easeFactor - 2.8) < 0.0001)
    }

    @Test func recoveryAfterFailureRestartsProgression() {
        var state = SM2Logic.State()
        state = SM2Logic.review(state, grade: 4) // 1
        state = SM2Logic.review(state, grade: 4) // 6
        state = SM2Logic.review(state, grade: 1) // fail → reset
        #expect(state.interval == 1)
        #expect(state.repetitions == 0)
        state = SM2Logic.review(state, grade: 4)
        #expect(state.interval == 1) // progression restarts
        #expect(state.repetitions == 1)
    }

    // MARK: - Due date & auto-grade

    @Test func dueDateAddsIntervalDaysFromStartOfDay() {
        let reviewed = calendar.date(from: DateComponents(year: 2026, month: 7, day: 11, hour: 22))!
        let state = SM2Logic.State(easeFactor: 2.5, interval: 6, repetitions: 2)
        let due = SM2Logic.dueDate(after: state, reviewedOn: reviewed, calendar: calendar)
        let expected = calendar.date(from: DateComponents(year: 2026, month: 7, day: 17))!
        #expect(due == expected)
    }

    @Test func autoGradeMapsCorrectnessAndSpeed() {
        #expect(SM2Logic.gradeForAnswer(correct: false, timeSpent: 5) == 2)
        #expect(SM2Logic.gradeForAnswer(correct: true, timeSpent: 30) == 5)
        #expect(SM2Logic.gradeForAnswer(correct: true, timeSpent: 90) == 4)
        #expect(SM2Logic.gradeForAnswer(correct: true, timeSpent: 60) == 5) // threshold is exclusive
    }
}
