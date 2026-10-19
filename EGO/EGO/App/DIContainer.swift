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
    let questionRepository: QuestionRepository
    let reviewItemRepository: ReviewItemRepository
    let essayRepository: EssayRepository
    let flashcardRepository: EssayFlashcardRepository
    let mascotEvents: MascotEventCenter
    let routineProgressService: RoutineProgressService
    let goalProgressService: GoalProgressService
    let xpService: XPService
    let questionAttemptService: QuestionAttemptService
    let flashcardReviewService: FlashcardReviewService
    let essayService: EssayService
    let contentSeedService: ContentSeedService
    let notificationSettingsStore: NotificationSettingsStore
    let phraseSelector: MotivationalPhraseSelectorProtocol
    let phraseSeedService: PhraseSeedService
    let notificationService: NotificationService
    let cardPresenter: MotivationalCardPresenter
    let notificationDelegate: NotificationDelegateAdapter
    let streakFreezeService: StreakFreezeService
    let sessionCompletionService: SessionCompletionService
    let focusActivityController: FocusActivityManaging
    let appGroupStore: AppGroupStore

    /// Shared timer state: Home's focus flow and the motivational card's
    /// "Focar agora" flow drive the same instance (one source of truth for
    /// cycles/Live Activity).
    lazy var pomodoroViewModel: PomodoroViewModel = makePomodoroViewModel()

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
        self.questionRepository = SwiftDataQuestionRepository(container: modelContainer)
        self.reviewItemRepository = SwiftDataReviewItemRepository(container: modelContainer)
        self.essayRepository = SwiftDataEssayRepository(container: modelContainer)
        self.flashcardRepository = SwiftDataEssayFlashcardRepository(container: modelContainer)
        self.mascotEvents = MascotEventCenter()
        self.routineProgressService = RoutineProgressService(
            routineRepository: routineRepository,
            routineLogRepository: routineLogRepository
        )
        self.goalProgressService = GoalProgressService(goalRepository: topicGoalRepository)
        self.xpService = XPService(
            userProfileRepository: userProfileRepository,
            mascotEvents: mascotEvents
        )
        self.questionAttemptService = QuestionAttemptService(
            modelContainer: modelContainer,
            reviewItemRepository: reviewItemRepository,
            userStatsRepository: userStatsRepository,
            subjectStatRepository: subjectStatRepository,
            goalProgressService: goalProgressService,
            xpService: xpService,
            mascotEvents: mascotEvents
        )
        self.flashcardReviewService = FlashcardReviewService(
            reviewItemRepository: reviewItemRepository
        )
        self.essayService = EssayService(
            essayRepository: essayRepository,
            userStatsRepository: userStatsRepository,
            goalProgressService: goalProgressService,
            xpService: xpService,
            mascotEvents: mascotEvents
        )
        self.contentSeedService = ContentSeedService(
            questionRepository: questionRepository,
            essayRepository: essayRepository,
            flashcardRepository: flashcardRepository
        )
        self.notificationSettingsStore = NotificationSettingsStore()
        let selector = MotivationalPhraseSelector(repository: notificationTemplateRepository)
        self.phraseSelector = selector
        self.phraseSeedService = PhraseSeedService(repository: notificationTemplateRepository)
        self.notificationService = NotificationService(
            scheduler: UserNotificationScheduler(),
            reminderRepository: reminderRepository,
            templateRepository: notificationTemplateRepository,
            streakRepository: streakRepository,
            userStatsRepository: userStatsRepository,
            userProfileRepository: userProfileRepository,
            focusRepository: focusRepository,
            phraseSelector: selector,
            settingsStore: notificationSettingsStore
        )
        let presenter = MotivationalCardPresenter(
            templateRepository: notificationTemplateRepository,
            phraseSelector: selector
        )
        self.cardPresenter = presenter
        self.notificationDelegate = NotificationDelegateAdapter { phraseId, categoryRaw in
            presenter.presentDeepLink(phraseId: phraseId, categoryRaw: categoryRaw)
        }
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
            routineProgressService: routineProgressService,
            subjectStatRepository: subjectStatRepository,
            reviewItemRepository: reviewItemRepository
        )
    }

    func makeGoalsViewModel() -> GoalsViewModel {
        GoalsViewModel(goalRepository: topicGoalRepository)
    }

    func makeQuestionBankViewModel() -> QuestionBankViewModel {
        QuestionBankViewModel(
            questionRepository: questionRepository,
            reviewItemRepository: reviewItemRepository
        )
    }

    func makePracticeViewModel(
        questions: [Question],
        isReview: Bool,
        timed: Bool
    ) -> PracticeViewModel {
        PracticeViewModel(
            questions: questions,
            isReview: isReview,
            timed: timed,
            attemptService: questionAttemptService,
            mascotEvents: mascotEvents
        )
    }

    func makeEssayHomeViewModel() -> EssayHomeViewModel {
        EssayHomeViewModel(essayRepository: essayRepository)
    }

    func makeEssayEditorViewModel(draft: EssayDraft) -> EssayEditorViewModel {
        EssayEditorViewModel(
            draft: draft,
            essayRepository: essayRepository,
            essayService: essayService
        )
    }

    func makeRepertorioViewModel() -> RepertorioViewModel {
        RepertorioViewModel(
            flashcardRepository: flashcardRepository,
            reviewItemRepository: reviewItemRepository,
            reviewService: flashcardReviewService
        )
    }

    func makeRepertorioStudyViewModel(cards: [EssayFlashcard]) -> RepertorioStudyViewModel {
        RepertorioStudyViewModel(
            cards: cards,
            reviewService: flashcardReviewService,
            mascotEvents: mascotEvents
        )
    }

    func makePomodoroViewModel() -> PomodoroViewModel {
        let viewModel = PomodoroViewModel(
            completionService: sessionCompletionService,
            mascotEvents: mascotEvents,
            streakRepository: streakRepository,
            goalRepository: topicGoalRepository,
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
