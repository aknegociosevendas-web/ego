import Foundation
import Testing
@testable import EGO

/// Soft-focus honor mode (docs/06 §7): leaving mid-focus beyond the grace
/// window abandons the session.
@MainActor
struct SoftFocusTests {
    func makeStack() throws -> (PomodoroViewModel, SpyNotificationScheduler, DIContainer) {
        let container = try PersistenceController.makeInMemoryContainer()
        let di = DIContainer(modelContainer: container)
        let spy = SpyNotificationScheduler()
        let notifications = NotificationService(
            scheduler: spy,
            reminderRepository: di.reminderRepository,
            templateRepository: di.notificationTemplateRepository,
            streakRepository: di.streakRepository,
            userStatsRepository: di.userStatsRepository,
            userProfileRepository: di.userProfileRepository,
            focusRepository: di.focusRepository,
            phraseSelector: MotivationalPhraseSelector(
                repository: di.notificationTemplateRepository
            ),
            settingsStore: NotificationSettingsStore(
                defaults: UserDefaults(suiteName: "test.\(UUID().uuidString)")!
            )
        )
        let viewModel = PomodoroViewModel(
            completionService: di.sessionCompletionService,
            mascotEvents: di.mascotEvents,
            streakRepository: di.streakRepository,
            goalRepository: di.topicGoalRepository,
            activityController: SpyFocusActivityController(),
            notificationService: notifications
        )
        return (viewModel, spy, di)
    }

    @Test func leavingSchedulesWarningAndReturningInGraceContinues() async throws {
        let (viewModel, spy, di) = try makeStack()
        defer { withExtendedLifetime(di) {} }

        viewModel.start()
        let leftAt = Date.now
        viewModel.appDidEnterBackground(at: leftAt)
        // The warning is scheduled asynchronously.
        try await Task.sleep(for: .milliseconds(200))
        #expect(spy.scheduled.contains {
            $0.identifier == NotificationConfig.Identifier.softFocusWarning
                && $0.afterInterval != nil
        })

        viewModel.appDidBecomeActive(at: leftAt.addingTimeInterval(10))
        #expect(spy.cancelled.contains(NotificationConfig.Identifier.softFocusWarning))
        #expect(viewModel.timerState == .running)
        #expect(try di.focusRepository.fetchAll().isEmpty)
    }

    @Test func returningAfterGraceAbandonsWithMinutesUntilLeaving() throws {
        let (viewModel, _, di) = try makeStack()
        defer { withExtendedLifetime(di) {} }

        viewModel.start()
        // Left 5 minutes into a 25-minute focus, stayed away 60s (> 30s grace).
        let leftAt = Date.now.addingTimeInterval(5 * 60)
        viewModel.appDidEnterBackground(at: leftAt)
        viewModel.appDidBecomeActive(at: leftAt.addingTimeInterval(60))

        #expect(viewModel.timerState == .idle)
        let sessions = try di.focusRepository.fetchAll()
        #expect(sessions.count == 1)
        #expect(sessions[0].abandoned)
        #expect(sessions[0].actualMinutes == 5)
        #expect(di.mascotEvents.state == .sad)
    }

    @Test func shieldOffIgnoresLeaving() throws {
        let (viewModel, spy, di) = try makeStack()
        defer { withExtendedLifetime(di) {} }

        viewModel.softFocusEnabled = false
        viewModel.start()
        let leftAt = Date.now
        viewModel.appDidEnterBackground(at: leftAt)
        viewModel.appDidBecomeActive(at: leftAt.addingTimeInterval(600))

        #expect(viewModel.timerState == .running)
        #expect(spy.scheduled.isEmpty)
        #expect(try di.focusRepository.fetchAll().isEmpty)
    }

    @Test func guardingMascotOnlyWhileShieldedFocusRuns() throws {
        let (viewModel, _, di) = try makeStack()
        defer { withExtendedLifetime(di) {} }

        #expect(viewModel.timerMascotState != .guarding)
        viewModel.start()
        #expect(viewModel.timerMascotState == .guarding)
        viewModel.softFocusEnabled = false
        #expect(viewModel.timerMascotState == .studying)
    }
}
