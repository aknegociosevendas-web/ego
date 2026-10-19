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
    var delivered: [Date] = []

    func requestAuthorization() async -> Bool { authorized }
    func isAuthorized() async -> Bool { authorized }
    func schedule(_ notification: PlannedNotification) async { scheduled.append(notification) }
    func cancel(identifiers: [String]) { cancelled.append(contentsOf: identifiers) }
    func deliveredDates(identifierPrefix: String) async -> [Date] { delivered }
}

@MainActor
struct NotificationServiceTests {
    func makeStack() throws -> (
        DIContainer, NotificationService, SpyNotificationScheduler, NotificationSettingsStore
    ) {
        let container = try PersistenceController.makeInMemoryContainer()
        let di = DIContainer(modelContainer: container)
        let spy = SpyNotificationScheduler()
        // Isolated defaults: the seed-version gate and settings must not leak
        // between tests (or from the host app).
        let defaults = UserDefaults(suiteName: "test.\(UUID().uuidString)")!
        PhraseSeedService(
            repository: di.notificationTemplateRepository, defaults: defaults
        ).seedIfNeeded()
        let store = NotificationSettingsStore(defaults: defaults)
        let service = NotificationService(
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
            settingsStore: store
        )
        return (di, service, spy, store)
    }

    @Test func optInCreatesDefaultReminderAndSchedulesIt() async throws {
        let (di, service, spy, _) = try makeStack()

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
        // Deep-link payload rides along (slice 7).
        #expect(spy.scheduled.allSatisfy { $0.userInfo["category"] != nil })
    }

    @Test func deniedPermissionSchedulesNothing() async throws {
        let (di, service, spy, _) = try makeStack()
        defer { withExtendedLifetime(di) {} }
        spy.authorized = false

        let granted = await service.requestPermissionAndEnable()

        #expect(!granted)
        #expect(spy.scheduled.isEmpty)
    }

    @Test func refreshSchedulesComebackAfterIdleDays() async throws {
        let (di, service, spy, _) = try makeStack()
        let stats = try di.userStatsRepository.fetchOrCreate()
        stats.lastActiveDay = Calendar.current.date(byAdding: .day, value: -2, to: .now)
        try di.userStatsRepository.save()

        await service.refreshSchedules()

        #expect(spy.scheduled.contains {
            $0.identifier == NotificationConfig.Identifier.motivationalComeback
        })
    }

    @Test func refreshSchedulesNoComebackWhenActiveToday() async throws {
        let (di, service, spy, _) = try makeStack()
        let stats = try di.userStatsRepository.fetchOrCreate()
        stats.lastActiveDay = .now
        try di.userStatsRepository.save()

        await service.refreshSchedules()

        #expect(!spy.scheduled.contains {
            $0.identifier == NotificationConfig.Identifier.motivationalComeback
        })
    }

    @Test func disabledCategoryIsNotScheduled() async throws {
        let (di, service, spy, store) = try makeStack()
        defer { withExtendedLifetime(di) {} }
        store.defaults.set(false, forKey: NotificationCategory.morningBoost.settingsKey)

        await service.refreshSchedules()

        #expect(!spy.scheduled.contains {
            $0.identifier == NotificationConfig.Identifier.motivationalMorning
        })
    }

    @Test func completingSessionCancelsStreakRiskNudges() throws {
        let (di, service, spy, _) = try makeStack()
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

        #expect(spy.cancelled.contains(NotificationConfig.Identifier.motivationalStreakRisk1))
        #expect(spy.cancelled.contains(NotificationConfig.Identifier.motivationalStreakRisk2))
        #expect(spy.cancelled.contains(NotificationConfig.Identifier.motivationalAfternoon))
    }

    @Test func openingAppSoonAfterDeliverySuppressesMotivationals() async throws {
        let (di, service, spy, store) = try makeStack()
        defer { withExtendedLifetime(di) {} }
        let now = Date.now
        spy.delivered = [now.addingTimeInterval(-5 * 60)]

        await service.appDidBecomeActive(now: now)

        let until = store.suppressedUntil
        #expect(until != nil)
        #expect((until ?? .distantPast) > now.addingTimeInterval(3.9 * 3_600))
        // Morning nudge is moot once the app opens.
        #expect(spy.cancelled.contains(NotificationConfig.Identifier.motivationalMorning))
    }

    @Test func openingAppLongAfterDeliveryDoesNotSuppress() async throws {
        let (di, service, spy, store) = try makeStack()
        defer { withExtendedLifetime(di) {} }
        let now = Date.now
        spy.delivered = [now.addingTimeInterval(-2 * 3_600)]

        await service.appDidBecomeActive(now: now)

        #expect(store.suppressedUntil == nil)
    }

    @Test func testNotificationFiresGenericPhraseInFiveSeconds() async throws {
        let (di, service, spy, _) = try makeStack()
        defer { withExtendedLifetime(di) {} }

        let sent = await service.sendTestNotification()

        #expect(sent)
        let test = spy.scheduled.first {
            $0.identifier == NotificationConfig.Identifier.motivationalTest
        }
        #expect(test?.afterInterval == 5)
        #expect(test?.userInfo["category"] == NotificationCategory.generic.rawValue)
        #expect(test?.body.isEmpty == false)
    }
}
