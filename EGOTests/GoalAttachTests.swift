import Foundation
import Testing
@testable import EGO

/// Explicit goal attach in the Pomodoro (F-01, slice 2.2).
@MainActor
struct GoalAttachTests {
    func makeStack() throws -> (PomodoroViewModel, DIContainer) {
        let container = try PersistenceController.makeInMemoryContainer()
        let di = DIContainer(modelContainer: container)
        let viewModel = PomodoroViewModel(
            completionService: di.sessionCompletionService,
            mascotEvents: di.mascotEvents,
            streakRepository: di.streakRepository,
            goalRepository: di.topicGoalRepository,
            activityController: SpyFocusActivityController(),
            notificationService: di.notificationService
        )
        return (viewModel, di)
    }

    @Test func selectingGoalDrivesSubjectAndLocksIt() throws {
        let (viewModel, di) = try makeStack()
        defer { withExtendedLifetime(di) {} }
        let goal = try di.topicGoalRepository.create(
            subject: "Física", topic: "Cinemática", targetHours: 5, targetQuestions: nil, deadline: nil
        )

        viewModel.refreshGoals()
        #expect(viewModel.availableGoals.count == 1)
        #expect(viewModel.availableGoals[0].title == "Cinemática")

        viewModel.selectGoal(goal.id)
        #expect(viewModel.selectedSubject == "Física")
        #expect(viewModel.isSubjectLockedByGoal)

        viewModel.selectGoal(nil)
        #expect(!viewModel.isSubjectLockedByGoal)
        // Subject stays as-is; only the lock is released.
        #expect(viewModel.selectedSubject == "Física")
    }

    @Test func completedGoalsAreNotOffered() throws {
        let (viewModel, di) = try makeStack()
        defer { withExtendedLifetime(di) {} }
        let goal = try di.topicGoalRepository.create(
            subject: "Física", topic: nil, targetHours: 1, targetQuestions: nil, deadline: nil
        )
        goal.completed = true
        try di.topicGoalRepository.save()

        viewModel.refreshGoals()
        #expect(viewModel.availableGoals.isEmpty)
    }

    @Test func staleSelectionClearsOnRefresh() throws {
        let (viewModel, di) = try makeStack()
        defer { withExtendedLifetime(di) {} }
        let goal = try di.topicGoalRepository.create(
            subject: "Física", topic: nil, targetHours: 1, targetQuestions: nil, deadline: nil
        )
        viewModel.refreshGoals()
        viewModel.selectGoal(goal.id)

        try di.topicGoalRepository.delete(goal)
        viewModel.refreshGoals()

        #expect(viewModel.selectedGoalID == nil)
    }

    @Test func explicitAttachProgressesOnlyChosenGoal() throws {
        let di = try DIContainer(modelContainer: PersistenceController.makeInMemoryContainer())
        let chosen = try di.topicGoalRepository.create(
            subject: "Matemática", topic: "Funções", targetHours: 10, targetQuestions: nil, deadline: nil
        )
        let other = try di.topicGoalRepository.create(
            subject: "Matemática", topic: "Geometria", targetHours: 10, targetQuestions: nil, deadline: nil
        )

        let session = FocusSession(plannedMinutes: 50, subject: "Matemática")
        session.actualMinutes = 50
        session.goal = chosen
        try di.sessionCompletionService.completeSession(session)

        #expect(chosen.progressMinutes == 50)
        #expect(other.progressMinutes == 0)
        #expect(session.goal === chosen)
    }

    @Test func completingFocusAttachesSelectedGoal() async throws {
        let (viewModel, di) = try makeStack()
        defer { withExtendedLifetime(di) {} }
        let chosen = try di.topicGoalRepository.create(
            subject: "Matemática", topic: "Funções", targetHours: 10, targetQuestions: nil, deadline: nil
        )
        let other = try di.topicGoalRepository.create(
            subject: "Matemática", topic: "Geometria", targetHours: 10, targetQuestions: nil, deadline: nil
        )
        viewModel.refreshGoals()
        viewModel.selectGoal(chosen.id)
        viewModel.configuration = PomodoroConfiguration(
            focusMinutes: 0, shortBreakMinutes: 0, longBreakMinutes: 0, cyclesBeforeLongBreak: 4
        )

        viewModel.start()
        try await Task.sleep(for: .milliseconds(1200))

        #expect(viewModel.phase == .shortBreak)
        let sessions = try di.focusRepository.fetchAll()
        #expect(sessions.count == 1)
        #expect(sessions[0].goal === chosen)
        #expect(other.progressMinutes == 0)
    }
}
