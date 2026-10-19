import Foundation
import Observation

/// F-07 practice/review session: one question at a time, immediate feedback,
/// SM-2 handled by the attempt service. Identifiable so views can present it.
@MainActor
@Observable
final class PracticeViewModel: Identifiable {
    struct Feedback: Equatable {
        let correct: Bool
        let explanation: String?
        let source: String?
    }

    let id = UUID()
    let isReview: Bool
    let timed: Bool

    private let attemptService: QuestionAttemptService
    private let mascotEvents: MascotEventCenter
    private(set) var questions: [Question]
    private(set) var index = 0
    private(set) var feedback: Feedback?
    private(set) var selectedIndex: Int?
    private(set) var correctCount = 0
    private(set) var correctStreak = 0
    private(set) var isMarked = false
    private(set) var questionStartedAt = Date.now

    init(
        questions: [Question],
        isReview: Bool,
        timed: Bool,
        attemptService: QuestionAttemptService,
        mascotEvents: MascotEventCenter
    ) {
        self.questions = questions.shuffled()
        self.isReview = isReview
        self.timed = timed
        self.attemptService = attemptService
        self.mascotEvents = mascotEvents
    }

    var current: Question? {
        questions.indices.contains(index) ? questions[index] : nil
    }

    var total: Int { questions.count }
    var isFinished: Bool { index >= questions.count }

    func answer(_ optionIndex: Int) {
        guard feedback == nil, let question = current else { return }
        let timeSpent = Int(Date.now.timeIntervalSince(questionStartedAt))
        let result = try? attemptService.recordAnswer(
            question: question,
            chosenIndex: optionIndex,
            timeSpent: timeSpent,
            isReview: isReview
        )
        selectedIndex = optionIndex
        let correct = result?.correct ?? (optionIndex == question.correctIndex)
        if correct {
            correctCount += 1
            correctStreak += 1
            // Celebrate every 3 in a row (F-07 mascot hook).
            if correctStreak >= 3, correctStreak.isMultiple(of: 3) {
                mascotEvents.questionStreak()
            }
        } else {
            correctStreak = 0
        }
        isMarked = (question.reviewItems ?? []).contains { $0.dueDate != nil }
        feedback = Feedback(
            correct: correct,
            explanation: question.explanation,
            source: question.source
        )
    }

    func markForReview() {
        guard let question = current else { return }
        try? attemptService.markForReview(question)
        isMarked = true
    }

    func next() {
        index += 1
        feedback = nil
        selectedIndex = nil
        isMarked = false
        questionStartedAt = .now
    }
}
