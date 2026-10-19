import Foundation
import Testing
@testable import EGO

@MainActor
struct GoalProgressTests {
    func makeContext() throws -> DIContainer {
        let container = try PersistenceController.makeInMemoryContainer()
        return DIContainer(modelContainer: container)
    }

    // MARK: - Pure math

    @Test func goalLogicAchievementAtExactThreshold() {
        let goal = TopicGoal(subject: "Matemática", targetHours: 2)
        goal.progressMinutes = 119
        #expect(!GoalLogic.isAchieved(goal))
        goal.progressMinutes = 120
        #expect(GoalLogic.isAchieved(goal))
        #expect(GoalLogic.hoursProgress(goal) == 1)
    }

    @Test func goalWithoutTargetNeverAutoCompletes() {
        let goal = TopicGoal(subject: "Matemática")
        goal.progressMinutes = 10_000
        #expect(!GoalLogic.isAchieved(goal))
        #expect(GoalLogic.hoursProgress(goal) == 0)
    }

    @Test func questionTargetGatesAchievement() {
        let goal = TopicGoal(subject: "Matemática", targetQuestions: 3)
        goal.progressQuestions = 2
        #expect(!GoalLogic.isAchieved(goal))
        #expect(GoalLogic.questionsProgress(goal) == 2.0 / 3.0)
        goal.progressQuestions = 3
        #expect(GoalLogic.isAchieved(goal))
        #expect(GoalLogic.questionsProgress(goal) == 1)
    }

    @Test func hoursPlusQuestionsGoalRequiresBoth() {
        let goal = TopicGoal(subject: "Matemática", targetHours: 1, targetQuestions: 2)
        goal.progressMinutes = 60      // hours met
        goal.progressQuestions = 1     // questions not met
        #expect(!GoalLogic.isAchieved(goal))
        goal.progressQuestions = 2
        #expect(GoalLogic.isAchieved(goal))
    }

    // MARK: - Session attribution (integration)

    @Test func sessionFeedsMatchingSubjectGoals() throws {
        let di = try makeContext()
        let math = try di.topicGoalRepository.create(
            subject: "Matemática", topic: "Funções", targetHours: 10, targetQuestions: nil, deadline: nil
        )
        let essay = try di.topicGoalRepository.create(
            subject: "Redação", topic: nil, targetHours: 5, targetQuestions: nil, deadline: nil
        )

        let session = FocusSession(plannedMinutes: 50, subject: "Matemática")
        session.actualMinutes = 50
        try di.sessionCompletionService.completeSession(session)

        #expect(math.progressMinutes == 50)
        #expect(essay.progressMinutes == 0)
        #expect(session.goal === math)
    }

    @Test func completingGoalAwardsBonusXPAndReportsIt() throws {
        let di = try makeContext()
        let goal = try di.topicGoalRepository.create(
            subject: "Matemática", topic: nil, targetHours: 1, targetQuestions: nil, deadline: nil
        )
        goal.progressMinutes = 40 // 20 min away from the 60-min target
        try di.topicGoalRepository.save()

        let session = FocusSession(plannedMinutes: 25, subject: "Matemática")
        session.actualMinutes = 25
        let result = try di.sessionCompletionService.completeSession(session)

        #expect(goal.completed)
        #expect(result.goalsCompleted == 1)
        // 25 min + 10 session bonus + 40 goal bonus.
        #expect(result.xpEarned == 75)
        let profile = try di.userProfileRepository.fetchOrCreate()
        #expect(profile.xp == 75)
    }

    // MARK: - Question attribution (integration, F-10 regression)

    private func seedQuestions(
        _ di: DIContainer, subject: String, count: Int
    ) throws -> [Question] {
        let items = (0..<count).map { i in
            QuestionPackImporter.Item(
                externalId: "q-\(subject)-\(i)", exam: "ENEM", year: 2024, subject: subject,
                topic: "Funções", difficulty: 2, statement: "2 + 2?",
                options: ["3", "4", "5"], correctIndex: 1,
                explanation: nil, source: nil, licenseNote: nil
            )
        }
        try di.questionRepository.upsert(items)
        return try di.questionRepository.fetchAll().filter { $0.subject == subject }
    }

    @Test func answeringQuestionsFeedsMatchingGoalAndCompletesIt() throws {
        let di = try makeContext()
        let goal = try di.topicGoalRepository.create(
            subject: "Matemática", topic: nil, targetHours: nil, targetQuestions: 2, deadline: nil
        )
        let other = try di.topicGoalRepository.create(
            subject: "História", topic: nil, targetHours: nil, targetQuestions: 2, deadline: nil
        )
        let questions = try seedQuestions(di, subject: "Matemática", count: 2)

        let first = try di.questionAttemptService.recordAnswer(
            question: questions[0], chosenIndex: 1, timeSpent: 20, isReview: false
        )
        #expect(goal.progressQuestions == 1)
        #expect(!goal.completed)
        #expect(first.goalsCompleted == 0)

        let second = try di.questionAttemptService.recordAnswer(
            question: questions[1], chosenIndex: 1, timeSpent: 20, isReview: false
        )
        #expect(goal.progressQuestions == 2)
        #expect(goal.completed)
        #expect(second.goalsCompleted == 1)
        #expect(other.progressQuestions == 0) // different subject → untouched

        // 3 XP × 2 correct + 40 goal bonus = 46 (below the level-2 threshold).
        #expect(second.xpEarned == 43) // 3 (this answer) + 40 (goal bonus)
        #expect(try di.userProfileRepository.fetchOrCreate().xp == 46)
        #expect(di.mascotEvents.state == .happy) // goal-completed reaction
    }

    @Test func wrongAnswersStillCountTowardQuestionGoal() throws {
        let di = try makeContext()
        let goal = try di.topicGoalRepository.create(
            subject: "Matemática", topic: nil, targetHours: nil, targetQuestions: 2, deadline: nil
        )
        let questions = try seedQuestions(di, subject: "Matemática", count: 2)

        // One wrong, one right — both are attempts (mirrors questionsSolved).
        try di.questionAttemptService.recordAnswer(
            question: questions[0], chosenIndex: 0, timeSpent: 20, isReview: false
        )
        try di.questionAttemptService.recordAnswer(
            question: questions[1], chosenIndex: 1, timeSpent: 20, isReview: false
        )
        #expect(goal.progressQuestions == 2)
        #expect(goal.completed)
    }

    @Test func completedGoalStopsAccumulating() throws {
        let di = try makeContext()
        let goal = try di.topicGoalRepository.create(
            subject: "Matemática", topic: nil, targetHours: 1, targetQuestions: nil, deadline: nil
        )
        goal.progressMinutes = 60
        goal.completed = true
        try di.topicGoalRepository.save()

        let session = FocusSession(plannedMinutes: 25, subject: "Matemática")
        session.actualMinutes = 25
        let result = try di.sessionCompletionService.completeSession(session)

        #expect(goal.progressMinutes == 60)
        #expect(result.goalsCompleted == 0)
    }
}
