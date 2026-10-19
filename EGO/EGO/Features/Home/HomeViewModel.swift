import Foundation
import Observation

/// Home dashboard state: mascot, streak, today's focus, level.
@MainActor
@Observable
final class HomeViewModel {
    private let focusRepository: FocusRepository
    private let userStatsRepository: UserStatsRepository
    private let userProfileRepository: UserProfileRepository
    private let streakRepository: StreakRepository
    private let walletRepository: WalletRepository
    private let freezeService: StreakFreezeService
    private let mascotEvents: MascotEventCenter
    private let appGroupStore: AppGroupStore
    private let config: GamificationConfig
    private let calendar: Calendar

    private(set) var currentStreak = 0
    private(set) var todayFocusMinutes = 0
    private(set) var level = 1
    private(set) var coins = 0
    private(set) var freezesAvailable = 0
    private(set) var freezePurchaseError: StreakFreezeService.PurchaseError?

    init(
        focusRepository: FocusRepository,
        userStatsRepository: UserStatsRepository,
        userProfileRepository: UserProfileRepository,
        streakRepository: StreakRepository,
        walletRepository: WalletRepository,
        freezeService: StreakFreezeService,
        mascotEvents: MascotEventCenter,
        appGroupStore: AppGroupStore,
        config: GamificationConfig = .standard,
        calendar: Calendar = .current
    ) {
        self.focusRepository = focusRepository
        self.userStatsRepository = userStatsRepository
        self.userProfileRepository = userProfileRepository
        self.streakRepository = streakRepository
        self.walletRepository = walletRepository
        self.freezeService = freezeService
        self.mascotEvents = mascotEvents
        self.appGroupStore = appGroupStore
        self.config = config
        self.calendar = calendar
    }

    // MARK: - Freeze shop

    var freezePrice: Int { freezeService.price }
    var maxFreezes: Int { freezeService.maxFreezes }

    var canBuyFreeze: Bool {
        coins >= freezePrice && freezesAvailable < maxFreezes
    }

    func buyFreeze() {
        do {
            try freezeService.buyFreeze()
            freezePurchaseError = nil
        } catch let error as StreakFreezeService.PurchaseError {
            freezePurchaseError = error
        } catch {
            freezePurchaseError = nil
        }
        refresh()
    }

    var mascotState: MascotState { mascotEvents.state }

    func refresh() {
        guard
            let stats = try? userStatsRepository.fetchOrCreate(),
            let profile = try? userProfileRepository.fetchOrCreate()
        else { return }
        currentStreak = stats.currentStreak
        level = profile.level
        coins = (try? walletRepository.fetchOrCreateWallet().coins) ?? 0
        freezesAvailable = (try? streakRepository.fetchOrCreate().freezesAvailable) ?? 0

        let today = calendar.startOfDay(for: .now)
        let dayInterval = DateInterval(start: today, duration: 86_400)
        let sessions = (try? focusRepository.completedSessions(in: dayInterval)) ?? []
        todayFocusMinutes = sessions.reduce(0) { $0 + $1.actualMinutes }

        // Cheap state for widgets (docs/02 §6).
        appGroupStore.writeSnapshot(
            currentStreak: currentStreak,
            todayFocusMinutes: todayFocusMinutes
        )

        evaluateStreakRisk()
    }

    /// Streak-at-risk check (F-04/F-13): worried baseline late in the day
    /// while today hasn't qualified yet.
    private func evaluateStreakRisk(now: Date = .now) {
        guard let streak = try? streakRepository.fetchOrCreate() else { return }
        let atRisk = StreakRiskLogic.isAtRisk(
            current: streak.current,
            lastQualifiedDay: streak.lastQualifiedDay,
            now: now,
            calendar: calendar,
            riskHour: config.streakRiskHour
        )
        mascotEvents.updateBaseline(atRisk ? .worried : .idle)
    }
}
