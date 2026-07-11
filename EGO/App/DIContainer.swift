import Foundation
import SwiftData

/// Service/repository registry, built once at launch and handed down by
/// constructor injection (docs/02 §4). Swap repositories for in-memory
/// variants in tests and previews.
@MainActor
final class DIContainer {
    let modelContainer: ModelContainer
    let focusRepository: FocusRepository
    let userProfileRepository: UserProfileRepository
    let userStatsRepository: UserStatsRepository
    let subjectStatRepository: SubjectStatRepository
    let streakRepository: StreakRepository
    let walletRepository: WalletRepository
    let reminderRepository: ReminderRepository
    let notificationTemplateRepository: NotificationTemplateRepository
    let routineRepository: RoutineRepository
    let routineLogRepository: RoutineLogRepository
    let topicGoalRepository: TopicGoalRepository
    let mascotEvents: MascotEventCenter
    let routineProgressService: RoutineProgressService
    let goalProgressService: GoalProgressService
    let notificationService: NotificationService
    let streakFreezeService: StreakFreezeService
    let sessionCompletionService: SessionCompletionService
    let focusActivityController: FocusActivityManaging
    let appGroupStore: AppGroupStore

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        self.focusRepository = SwiftDataFocusRepository(container: modelContainer)
        self.userProfileRepository = SwiftDataUserProfileRepository(container: modelContainer)
        self.userStatsRepository = SwiftDataUserStatsRepository(container: modelContainer)
        self.subjectStatRepository = SwiftDataSubjectStatRepository(container: modelContainer)
        self.streakRepository = SwiftDataStreakRepository(container: modelContainer)
        self.walletRepository = SwiftDataWalletRepository(container: modelContainer)
        self.reminderRepository = SwiftDataReminderRepository(container: modelContainer)
        self.notificationTemplateRepository = SwiftDataNotificationTemplateRepository(container: modelContainer)
        self.routineRepository = SwiftDataRoutineRepository(container: modelContainer)
        self.routineLogRepository = SwiftDataRoutineLogRepository(container: modelContainer)
        self.topicGoalRepository = SwiftDataTopicGoalRepository(container: modelContainer)
        self.mascotEvents = MascotEventCenter()
        self.routineProgressService = RoutineProgressService(
            routineRepository: routineRepository,
            routineLogRepository: routineLogRepository
        )
        self.goalProgressService = GoalProgressService(goalRepository: topicGoalRepository)
        self.notificationService = NotificationService(
            scheduler: UserNotificationScheduler(),
            reminderRepository: reminderRepository,
            templateRepository: notificationTemplateRepository,
            streakRepository: streakRepository,
            userStatsRepository: userStatsRepository,
            userProfileRepository: userProfileRepository
        )
        self.streakFreezeService = StreakFreezeService(
            streakRepository: streakRepository,
            walletRepository: walletRepository
        )
        self.sessionCompletionService = SessionCompletionService(
            focusRepository: focusRepository,
            userProfileRepository: userProfileRepository,
            userStatsRepository: userStatsRepository,
            subjectStatRepository: subjectStatRepository,
            streakRepository: streakRepository,
            walletRepository: walletRepository,
            mascotEvents: mascotEvents,
            notificationService: notificationService,
            routineProgressService: routineProgressService,
            goalProgressService: goalProgressService
        )
        self.focusActivityController = FocusActivityController()
        self.appGroupStore = AppGroupStore()
    }

    /// Housekeeping on scene background: keep the routine history at the
    /// 6-month window (F-06).
    func performBackgroundMaintenance(now: Date = .now) {
        if let cutoff = Calendar.current.date(byAdding: .day, value: -180, to: now) {
            try? routineLogRepository.prune(olderThan: cutoff)
        }
    }

    /// Throwaway in-memory graph for SwiftUI previews.
    static func preview() -> DIContainer {
        guard let container = try? PersistenceController.makeInMemoryContainer() else {
            fatalError("Could not create in-memory ModelContainer for previews")
        }
        return DIContainer(modelContainer: container)
    }

    // MARK: - ViewModel factories (constructor injection helpers)

    func makeHomeViewModel() -> HomeViewModel {
        HomeViewModel(
            focusRepository: focusRepository,
            userStatsRepository: userStatsRepository,
            userProfileRepository: userProfileRepository,
            streakRepository: streakRepository,
            walletRepository: walletRepository,
            freezeService: streakFreezeService,
            mascotEvents: mascotEvents,
            appGroupStore: appGroupStore
        )
    }

    func makeOnboardingViewModel() -> OnboardingViewModel {
        OnboardingViewModel(notificationService: notificationService)
    }

    func makeRoutinesViewModel() -> RoutinesViewModel {
        RoutinesViewModel(
            routineRepository: routineRepository,
            routineLogRepository: routineLogRepository,
            routineProgressService: routineProgressService
        )
    }

    func makeGoalsViewModel() -> GoalsViewModel {
        GoalsViewModel(goalRepository: topicGoalRepository)
    }

    func makePomodoroViewModel() -> PomodoroViewModel {
        let viewModel = PomodoroViewModel(
            completionService: sessionCompletionService,
            mascotEvents: mascotEvents,
            streakRepository: streakRepository,
            activityController: focusActivityController,
            notificationService: notificationService
        )
        #if DEBUG
        // UI-test hook: zero-length focus so the completion flow is testable.
        if ProcessInfo.processInfo.arguments.contains("-ui-test-short-focus") {
            viewModel.configuration = PomodoroConfiguration(
                focusMinutes: 0,
                shortBreakMinutes: 0,
                longBreakMinutes: 0,
                cyclesBeforeLongBreak: 4
            )
        }
        #endif
        return viewModel
    }

    func makeStatsViewModel() -> StatsViewModel {
        StatsViewModel(
            focusRepository: focusRepository,
            userStatsRepository: userStatsRepository,
            userProfileRepository: userProfileRepository,
            subjectStatRepository: subjectStatRepository,
            walletRepository: walletRepository
        )
    }
}
