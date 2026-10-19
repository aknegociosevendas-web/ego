import Foundation

/// Single exit point for a focus session: persists it, updates stats and
/// subject rollups, awards XP, appends coins to the wallet ledger, advances
/// the streak, and notifies the mascot.
@MainActor
final class SessionCompletionService {
    struct Result: Equatable {
        let xpEarned: Int
        let coinsEarned: Int
        let didLevelUp: Bool
        let newLevel: Int
        let streakOutcome: StreakLogic.Outcome
        let streakCurrent: Int
        let freezesEarned: Int
        let goalsCompleted: Int
    }

    private let focusRepository: FocusRepository
    private let userProfileRepository: UserProfileRepository
    private let userStatsRepository: UserStatsRepository
    private let subjectStatRepository: SubjectStatRepository
    private let streakRepository: StreakRepository
    private let walletRepository: WalletRepository
    private let mascotEvents: MascotEventCenter
    private let notificationService: NotificationService
    private let routineProgressService: RoutineProgressService
    private let goalProgressService: GoalProgressService
    private let config: GamificationConfig
    private let calendar: Calendar

    init(
        focusRepository: FocusRepository,
        userProfileRepository: UserProfileRepository,
        userStatsRepository: UserStatsRepository,
        subjectStatRepository: SubjectStatRepository,
        streakRepository: StreakRepository,
        walletRepository: WalletRepository,
        mascotEvents: MascotEventCenter,
        notificationService: NotificationService,
        routineProgressService: RoutineProgressService,
        goalProgressService: GoalProgressService,
        config: GamificationConfig = .standard,
        calendar: Calendar = .current
    ) {
        self.focusRepository = focusRepository
        self.userProfileRepository = userProfileRepository
        self.userStatsRepository = userStatsRepository
        self.subjectStatRepository = subjectStatRepository
        self.streakRepository = streakRepository
        self.walletRepository = walletRepository
        self.mascotEvents = mascotEvents
        self.notificationService = notificationService
        self.routineProgressService = routineProgressService
        self.goalProgressService = goalProgressService
        self.config = config
        self.calendar = calendar
    }

    /// `session.actualMinutes` must be set by the caller before completing.
    @discardableResult
    func completeSession(_ session: FocusSession, at date: Date = .now) throws -> Result {
        // Count before saving so the current session is excluded.
        let today = calendar.startOfDay(for: date)
        let dayInterval = DateInterval(start: today, duration: 86_400)
        let priorSessionsToday = try focusRepository.completedSessions(in: dayInterval).count

        session.completed = true
        session.abandoned = false
        session.endedAt = date
        session.updatedAt = date
        try focusRepository.save(session)

        let stats = try userStatsRepository.fetchOrCreate()
        stats.totalSessions += 1
        stats.totalFocusMinutes += session.actualMinutes
        stats.lastActiveDay = date
        stats.updatedAt = date

        if let subject = session.subject, !subject.isEmpty {
            let subjectStat = try subjectStatRepository.fetchOrCreate(
                subject: subject,
                attachedTo: stats
            )
            subjectStat.focusMinutes += session.actualMinutes
            subjectStat.updatedAt = date
        }

        // Routine history + goal progress (F-06/F-10).
        _ = try? routineProgressService.recordSession(session, at: date)
        let goalOutcome = (try? goalProgressService.recordSession(session, at: date)) ?? .init()

        let profile = try userProfileRepository.fetchOrCreate()
        let xp = GamificationLogic.xpEarned(
            forCompletedSessionMinutes: session.actualMinutes,
            config: config
        ) + goalOutcome.newlyCompletedGoals * config.xpPerGoalCompleted
        profile.xp += xp
        let newLevel = GamificationLogic.level(forXP: profile.xp)
        let didLevelUp = newLevel > profile.level
        profile.level = newLevel
        profile.updatedAt = date

        // Coins go to the wallet + append-only ledger (docs/07 §3);
        // UserProfile.coins is deprecated and no longer written.
        let coins = GamificationLogic.coinsEarned(priorSessionsToday: priorSessionsToday, config: config)
        let wallet = try walletRepository.fetchOrCreateWallet()
        if coins > 0 {
            wallet.coins += coins
            wallet.updatedAt = date
            try walletRepository.append(CoinTransaction(
                amount: coins,
                reason: CoinTransaction.Reason.sessionCompleted,
                date: date
            ))
        }

        let streak = try streakRepository.fetchOrCreate()
        let (newState, outcome) = StreakLogic.applyQualifyingEvent(
            on: date,
            to: StreakLogic.State(
                current: streak.current,
                longest: streak.longest,
                lastQualifiedDay: streak.lastQualifiedDay,
                freezesAvailable: streak.freezesAvailable,
                freezeUsedDates: streak.freezeUsedDates ?? []
            ),
            calendar: calendar
        )
        streak.current = newState.current
        streak.longest = newState.longest
        streak.lastQualifiedDay = newState.lastQualifiedDay
        streak.freezesAvailable = newState.freezesAvailable
        streak.freezeUsedDates = newState.freezeUsedDates
        streak.updatedAt = date
        stats.currentStreak = newState.current
        stats.longestStreak = newState.longest

        // Milestone crossings award a freeze, up to the cap (docs/07 §4).
        var freezesEarned = 0
        if outcome != .alreadyQualifiedToday,
           config.freezeMilestones.contains(newState.current),
           streak.freezesAvailable < config.maxFreezes {
            streak.freezesAvailable += 1
            freezesEarned = 1
        }

        try userStatsRepository.save()

        // Today qualified: cancel the risk nudge, push the comeback window.
        notificationService.sessionDidComplete()

        // Qualifying today clears any streak worry.
        mascotEvents.updateBaseline(.idle)
        if didLevelUp {
            mascotEvents.leveledUp()
        } else {
            mascotEvents.sessionCompleted()
        }

        return Result(
            xpEarned: xp,
            coinsEarned: coins,
            didLevelUp: didLevelUp,
            newLevel: newLevel,
            streakOutcome: outcome,
            streakCurrent: newState.current,
            freezesEarned: freezesEarned,
            goalsCompleted: goalOutcome.newlyCompletedGoals
        )
    }

    /// Abandoned sessions are recorded (history) but earn nothing (docs/07 §3).
    func abandonSession(_ session: FocusSession, at date: Date = .now) throws {
        session.abandoned = true
        session.completed = false
        session.endedAt = date
        session.updatedAt = date
        try focusRepository.save(session)
        mascotEvents.sessionAbandoned()
    }
}
