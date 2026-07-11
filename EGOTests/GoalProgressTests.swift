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
