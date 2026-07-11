import Foundation
import Testing
@testable import EGO

/// Records scheduler calls so orchestration is assertable without
/// UNUserNotificationCenter.
@MainActor
final class SpyNotificationScheduler: NotificationScheduling {
    var authorized = true
    var scheduled: [PlannedNotification] = []
    var cancelled: [String] = []

    func requestAuthorization() async -> Bool { authorized }
    func isAuthorized() async -> Bool { authorized }
    func schedule(_ notification: PlannedNotification) async { scheduled.append(notification) }
    func cancel(identifiers: [String]) { cancelled.append(contentsOf: identifiers) }
}

@MainActor
struct NotificationServiceTests {
    func makeStack() throws -> (DIContainer, NotificationService, SpyNotificationScheduler) {
        let container = try PersistenceController.makeInMemoryContainer()
        let di = DIContainer(modelContainer: container)
        let spy = SpyNotificationScheduler()
        let service = NotificationService(
            scheduler: spy,
            reminderRepository: di.reminderRepository,
            templateRepository: di.notificationTemplateRepository,
            streakRepository: di.streakRepository,
            userStatsRepository: di.userStatsRepository,
            userProfileRepository: di.userProfileRepository
        )
        return (di, service, spy)
    }

    @Test func optInCreatesDefaultReminderAndSchedulesIt() async throws {
        let (di, service, spy) = try makeStack()

        let granted = await service.requestPermissionAndEnable()

        #expect(granted)
        let reminder = try di.reminderRepository.sessionReminder()
        #expect(reminder != nil)
        #expect(spy.scheduled.contains {
            $0.identifier == NotificationConfig.Identifier.sessionReminder
                && $0.repeats
                && $0.dateComponents.hour == 18
        })
        // Phrases were seeded and used as the body.
        #expect(spy.scheduled.allSatisfy { !$0.body.isEmpty })
    }

    @Test func deniedPermissionSchedulesNothing() async throws {
        let (_, service, spy) = try makeStack()
        spy.authorized = false

        let granted = await service.requestPermissionAndEnable()

        #expect(!granted)
        #expect(spy.scheduled.isEmpty)
    }

    @Test func refreshSchedulesComebackAfterActivity() async throws {
        let (di, service, spy) = try makeStack()
        let stats = try di.userStatsRepository.fetchOrCreate()
        stats.lastActiveDay = .now
        try di.userStatsRepository.save()

        await service.refreshSchedules()

        #expect(spy.scheduled.contains {
            $0.identifier == NotificationConfig.Identifier.comeback
        })
    }

    @Test func completingSessionCancelsStreakRiskNudge() throws {
        let (di, service, spy) = try makeStack()
        // Wire a completion service that talks to the spy-backed notifications.
        let completion = SessionCompletionService(
            focusRepository: di.focusRepository,
            userProfileRepository: di.userProfileRepository,
            userStatsRepository: di.userStatsRepository,
            subjectStatRepository: di.subjectStatRepository,
            streakRepository: di.streakRepository,
            walletRepository: di.walletRepository,
            mascotEvents: di.mascotEvents,
            notificationService: service,
            routineProgressService: di.routineProgressService,
            goalProgressService: di.goalProgressService
        )

        let session = FocusSession(plannedMinutes: 25)
        session.actualMinutes = 25
        try completion.completeSession(session)

        #expect(spy.cancelled.contains(NotificationConfig.Identifier.streakRisk))
    }
}
