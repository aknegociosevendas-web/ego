import Foundation
import Testing
@testable import EGO

@MainActor
struct SuggestionLogicTests {
    func stat(_ subject: String, solved: Int, correct: Int) -> SubjectStat {
        let stat = SubjectStat(subject: subject)
        stat.questionsSolved = solved
        stat.questionsCorrect = correct
        return stat
    }

    @Test func picksWeakestSubjectWithEnoughSignal() {
        let suggestion = SuggestionLogic.weakestSubject(from: [
            stat("Matemática", solved: 20, correct: 8),   // 40%
            stat("Português", solved: 15, correct: 9),    // 60%
            stat("Física", solved: 12, correct: 11),      // 92% — above threshold
        ])
        #expect(suggestion?.subject == "Matemática")
        #expect(abs((suggestion?.accuracy ?? 0) - 0.4) < 0.0001)
    }

    @Test func ignoresSubjectsBelowMinimumAttempts() {
        let suggestion = SuggestionLogic.weakestSubject(from: [
            stat("Química", solved: 5, correct: 0), // too few answers
        ])
        #expect(suggestion == nil)
    }

    @Test func noSuggestionWhenEverythingIsAboveThreshold() {
        let suggestion = SuggestionLogic.weakestSubject(from: [
            stat("Matemática", solved: 30, correct: 27),
        ])
        #expect(suggestion == nil)
    }
}
