import Foundation
import Testing
@testable import EGO

@MainActor
struct QuestionAttemptServiceTests {
    func makeContext() throws -> DIContainer {
        let container = try PersistenceController.makeInMemoryContainer()
        return DIContainer(modelContainer: container)
    }

    func seedQuestion(_ di: DIContainer, subject: String = "Matemática") throws -> Question {
        let pack = QuestionPackImporter.Pack(
            version: 1, pack: "t",
            questions: [QuestionPackImporter.Item(
                externalId: "t-1", exam: "ENEM", year: 2024, subject: subject,
                topic: "Funções", difficulty: 2, statement: "2 + 2?",
                options: ["3", "4", "5"], correctIndex: 1,
                explanation: "Aritmética básica.", source: "Teste", licenseNote: nil
            )]
        )
        try di.questionRepository.upsert(pack.questions)
        return try di.questionRepository.fetchAll()[0]
    }

    @Test func correctAnswerFeedsStatsAndXP() throws {
        let di = try makeContext()
        let question = try seedQuestion(di)

        let result = try di.questionAttemptService.recordAnswer(
            question: question, chosenIndex: 1, timeSpent: 20, isReview: false
        )

        #expect(result.correct)
        #expect(result.xpEarned == 3)

        let stats = try di.userStatsRepository.fetchOrCreate()
        #expect(stats.questionsSolved == 1)
        #expect(stats.questionsCorrect == 1)

        let subjectStats = try di.subjectStatRepository.fetchAll()
        #expect(subjectStats.count == 1)
        #expect(subjectStats[0].questionsSolved == 1)
        #expect(subjectStats[0].questionsCorrect == 1)

        #expect(try di.userProfileRepository.fetchOrCreate().xp == 3)
        // Correct first-pass answers don't enter the queue.
        #expect(try di.reviewItemRepository.dueItems(on: .now.addingTimeInterval(90_000)).isEmpty)
    }

    @Test func wrongAnswerEntersReviewQueueDueTomorrow() throws {
        let di = try makeContext()
        let question = try seedQuestion(di)
        let calendar = Calendar.current

        let result = try di.questionAttemptService.recordAnswer(
            question: question, chosenIndex: 0, timeSpent: 20, isReview: false
        )

        #expect(!result.correct)
        #expect(result.xpEarned == 0)
        let stats = try di.userStatsRepository.fetchOrCreate()
        #expect(stats.questionsSolved == 1)
        #expect(stats.questionsCorrect == 0)

        let item = try #require(try di.reviewItemRepository.item(for: question))
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: .now))!
        #expect(item.dueDate == tomorrow)

        // A second wrong answer reuses the same item (no duplicates).
        try di.questionAttemptService.recordAnswer(
            question: question, chosenIndex: 2, timeSpent: 10, isReview: false
        )
        #expect(question.reviewItems?.count == 1)
        #expect(question.attempts?.count == 2)
    }

    @Test func reviewAnswerAdvancesSM2State() throws {
        let di = try makeContext()
        let question = try seedQuestion(di)
        _ = try di.reviewItemRepository.fetchOrCreate(for: question)

        // Quick correct answer in review mode → grade 5.
        try di.questionAttemptService.recordAnswer(
            question: question, chosenIndex: 1, timeSpent: 10, isReview: true
        )

        let item = try #require(try di.reviewItemRepository.item(for: question))
        #expect(item.lastGrade == 5)
        #expect(item.repetitions == 1)
        #expect(item.interval == 1)
        #expect(abs(item.easeFactor - 2.6) < 0.0001)
        #expect(item.dueDate != nil)
    }

    @Test func manualMarkEnqueuesWithoutAnswering() throws {
        let di = try makeContext()
        let question = try seedQuestion(di)

        try di.questionAttemptService.markForReview(question)

        let item = try #require(try di.reviewItemRepository.item(for: question))
        #expect(item.dueDate != nil)
        #expect(try di.userStatsRepository.fetchOrCreate().questionsSolved == 0)
    }
}
