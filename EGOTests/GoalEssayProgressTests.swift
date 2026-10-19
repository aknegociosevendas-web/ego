import Foundation
import SwiftData
import Testing
@testable import EGO

@MainActor
struct GoalEssayProgressTests {
    func makeContext() throws -> DIContainer {
        let container = try PersistenceController.makeInMemoryContainer()
        return DIContainer(modelContainer: container)
    }

    // MARK: - Pure math

    @Test func essayTargetGatesAchievement() {
        let goal = TopicGoal(subject: "Redação")
        goal.targetEssays = 3
        goal.progressEssays = 2
        #expect(!GoalLogic.isAchieved(goal))
        #expect(GoalLogic.essaysProgress(goal) == 2.0 / 3.0)
        goal.progressEssays = 3
        #expect(GoalLogic.isAchieved(goal))
        #expect(GoalLogic.essaysProgress(goal) == 1)
    }

    @Test func multiTargetRequiresEveryDefinedTarget() {
        let goal = TopicGoal(subject: "Redação", targetHours: 1)
        goal.targetEssays = 2
        goal.progressMinutes = 60      // hours met
        goal.progressEssays = 1        // essays not met
        #expect(!GoalLogic.isAchieved(goal))
        goal.progressEssays = 2        // both met
        #expect(GoalLogic.isAchieved(goal))
    }

    // MARK: - Essay attribution (integration)

    func makeEssayGoal(_ di: DIContainer, targetEssays: Int) throws -> TopicGoal {
        let goal = try di.topicGoalRepository.create(
            subject: "Redação", topic: nil, targetHours: nil, targetQuestions: nil, deadline: nil
        )
        goal.targetEssays = targetEssays
        try di.topicGoalRepository.save()
        return goal
    }

    func finalizeEssay(_ di: DIContainer) throws {
        let template = try di.essayRepository.templates().first
        let draft = try di.essayRepository.createDraft(template: template, title: "Teste")
        draft.bodyText = "Uma redação curta."
        try di.essayService.finalize(draft, competencyScores: [200, 200, 200, 200, 200])
    }

    @Test func finishedEssayFeedsAllActiveEssayGoalsAndCompletesThem() throws {
        let di = try makeContext()
        di.contentSeedService.seedIfNeeded()
        let goal = try makeEssayGoal(di, targetEssays: 2)
        let hoursGoal = try di.topicGoalRepository.create(
            subject: "Redação", topic: nil, targetHours: 5, targetQuestions: nil, deadline: nil
        )

        try finalizeEssay(di)
        #expect(goal.progressEssays == 1)
        #expect(!goal.completed)
        #expect(hoursGoal.progressEssays == 0) // no essay target → untouched

        try finalizeEssay(di)
        #expect(goal.progressEssays == 2)
        #expect(goal.completed)

        // 50 XP per essay (×2) + 40 goal bonus on completion. This total also
        // crosses the level-2 threshold (100 XP), so the level-up reaction
        // takes precedence over the goal reaction — mirrors the session path.
        #expect(try di.userProfileRepository.fetchOrCreate().xp == 140)
        #expect(di.mascotEvents.state == .levelUp)
    }

    @Test func completingEssayGoalWithoutLevelUpTriggersGoalMascot() throws {
        let di = try makeContext()
        di.contentSeedService.seedIfNeeded()
        let goal = try makeEssayGoal(di, targetEssays: 1)

        // 50 essay XP + 40 goal bonus = 90 XP, below the level-2 threshold.
        try finalizeEssay(di)
        #expect(goal.completed)
        #expect(try di.userProfileRepository.fetchOrCreate().xp == 90)
        #expect(di.mascotEvents.state == .happy)
    }

    @Test func completedEssayGoalStopsAccumulating() throws {
        let di = try makeContext()
        di.contentSeedService.seedIfNeeded()
        let goal = try makeEssayGoal(di, targetEssays: 1)

        try finalizeEssay(di)
        #expect(goal.completed)
        #expect(goal.progressEssays == 1)

        try finalizeEssay(di)
        #expect(goal.progressEssays == 1) // activeEssayGoals excludes completed
    }

    // MARK: - Real on-disk store (schema migration, golden rule)

    @Test func progressEssaysPersistsAcrossRealStoreReload() throws {
        let url = URL.temporaryDirectory.appending(
            path: "ego-essay-goal-\(UUID().uuidString).store"
        )
        defer { try? FileManager.default.removeItem(at: url) }
        let config = ModelConfiguration(
            schema: PersistenceController.schema, url: url, cloudKitDatabase: .none
        )

        let goalID: UUID
        do {
            let container = try ModelContainer(
                for: PersistenceController.schema, configurations: [config]
            )
            let goal = TopicGoal(subject: "Redação")
            goal.targetEssays = 3
            goal.progressEssays = 2
            container.mainContext.insert(goal)
            try container.mainContext.save()
            goalID = goal.id
        }

        // Reopen the same file to prove the new column round-trips on a real store.
        let reopened = try ModelContainer(
            for: PersistenceController.schema, configurations: [config]
        )
        let reloaded = try reopened.mainContext
            .fetch(FetchDescriptor<TopicGoal>())
            .first { $0.id == goalID }
        #expect(reloaded?.progressEssays == 2)
        #expect(reloaded?.targetEssays == 3)
    }
}
