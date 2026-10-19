import Foundation
import SwiftData

/// Single exit point for answering a question (F-07): records the attempt,
/// updates UserStats/SubjectStat, grants XP, and manages the SM-2 queue.
@MainActor
final class QuestionAttemptService {
    struct Result: Equatable {
        let correct: Bool
        let xpEarned: Int
        let didLevelUp: Bool
        let goalsCompleted: Int
    }

    private let context: ModelContext
    private let reviewItemRepository: ReviewItemRepository
    private let userStatsRepository: UserStatsRepository
    private let subjectStatRepository: SubjectStatRepository
    private let goalProgressService: GoalProgressService
    private let xpService: XPService
    private let mascotEvents: MascotEventCenter
    private let config: GamificationConfig
    private let calendar: Calendar

    init(
        modelContainer: ModelContainer,
        reviewItemRepository: ReviewItemRepository,
        userStatsRepository: UserStatsRepository,
        subjectStatRepository: SubjectStatRepository,
        goalProgressService: GoalProgressService,
        xpService: XPService,
        mascotEvents: MascotEventCenter,
        config: GamificationConfig = .standard,
        calendar: Calendar = .current
    ) {
        self.context = modelContainer.mainContext
        self.reviewItemRepository = reviewItemRepository
        self.userStatsRepository = userStatsRepository
        self.subjectStatRepository = subjectStatRepository
        self.goalProgressService = goalProgressService
        self.xpService = xpService
        self.mascotEvents = mascotEvents
        self.config = config
        self.calendar = calendar
    }

    @discardableResult
    func recordAnswer(
        question: Question,
        chosenIndex: Int,
        timeSpent: Int,
        isReview: Bool,
        at date: Date = .now
    ) throws -> Result {
        let correct = chosenIndex == question.correctIndex

        let attempt = QuestionAttempt(
            chosenIndex: chosenIndex,
            correct: correct,
            answeredAt: date,
            timeSpent: timeSpent
        )
        attempt.question = question
        context.insert(attempt)

        let stats = try userStatsRepository.fetchOrCreate()
        stats.questionsSolved += 1
        if correct { stats.questionsCorrect += 1 }
        stats.lastActiveDay = date
        stats.updatedAt = date

        if let subject = question.subject, !subject.isEmpty {
            let subjectStat = try subjectStatRepository.fetchOrCreate(
                subject: subject, attachedTo: stats
            )
            subjectStat.questionsSolved += 1
            if correct { subjectStat.questionsCorrect += 1 }
            subjectStat.updatedAt = date
        }

        // Topic-goal progress (F-10): attributed by the question's subject,
        // alongside the subject-stat rollup above.
        let goalOutcome = (try? goalProgressService.recordQuestion(question, at: date)) ?? .init()

        if isReview {
            // Scheduled review: run SM-2 with the auto-derived grade.
            let item = try reviewItemRepository.fetchOrCreate(for: question)
            let grade = SM2Logic.gradeForAnswer(correct: correct, timeSpent: timeSpent)
            let next = SM2Logic.review(
                SM2Logic.State(
                    easeFactor: item.easeFactor,
                    interval: item.interval,
                    repetitions: item.repetitions
                ),
                grade: grade
            )
            item.easeFactor = next.easeFactor
            item.interval = next.interval
            item.repetitions = next.repetitions
            item.lastGrade = grade
            item.dueDate = SM2Logic.dueDate(after: next, reviewedOn: date, calendar: calendar)
            item.updatedAt = date
        } else if !correct {
            // Wrong answers enter the queue, due tomorrow.
            try enqueue(question, at: date)
        }

        try userStatsRepository.save()

        let xp = (correct ? config.xpPerCorrectQuestion : 0)
            + goalOutcome.newlyCompletedGoals * config.xpPerGoalCompleted
        let didLevelUp = try xpService.grant(xp, at: date)
        // Level-up celebration (fired inside the grant) takes precedence.
        if goalOutcome.newlyCompletedGoals > 0, !didLevelUp {
            mascotEvents.goalCompleted()
        }

        return Result(
            correct: correct,
            xpEarned: xp,
            didLevelUp: didLevelUp,
            goalsCompleted: goalOutcome.newlyCompletedGoals
        )
    }

    /// Manual "marcar para revisão" (any time, answered or not).
    func markForReview(_ question: Question, at date: Date = .now) throws {
        try enqueue(question, at: date)
    }

    private func enqueue(_ question: Question, at date: Date) throws {
        let item = try reviewItemRepository.fetchOrCreate(for: question)
        if item.dueDate == nil {
            item.dueDate = calendar.date(
                byAdding: .day, value: 1, to: calendar.startOfDay(for: date)
            )
            item.updatedAt = date
        }
        try reviewItemRepository.save()
    }
}
