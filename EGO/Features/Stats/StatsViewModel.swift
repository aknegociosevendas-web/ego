import Foundation
import Observation

/// F-11 dashboard state, read from the denormalized rollups + a 7-day
/// session window for the trend chart.
@MainActor
@Observable
final class StatsViewModel {
    struct SubjectMinutes: Identifiable, Equatable {
        let subject: String
        let minutes: Int
        var id: String { subject }
    }

    private let focusRepository: FocusRepository
    private let userStatsRepository: UserStatsRepository
    private let userProfileRepository: UserProfileRepository
    private let subjectStatRepository: SubjectStatRepository
    private let walletRepository: WalletRepository
    private let calendar: Calendar

    private(set) var totalFocusMinutes = 0
    private(set) var totalSessions = 0
    private(set) var currentStreak = 0
    private(set) var longestStreak = 0
    private(set) var level = 1
    private(set) var xp = 0
    private(set) var coins = 0
    private(set) var subjects: [SubjectMinutes] = []
    private(set) var weekly: [StatsAggregator.DailyMinutes] = []

    init(
        focusRepository: FocusRepository,
        userStatsRepository: UserStatsRepository,
        userProfileRepository: UserProfileRepository,
        subjectStatRepository: SubjectStatRepository,
        walletRepository: WalletRepository,
        calendar: Calendar = .current
    ) {
        self.focusRepository = focusRepository
        self.userStatsRepository = userStatsRepository
        self.userProfileRepository = userProfileRepository
        self.subjectStatRepository = subjectStatRepository
        self.walletRepository = walletRepository
        self.calendar = calendar
    }

    // MARK: - Derived

    var totalFocusText: String {
        let hours = totalFocusMinutes / 60
        let minutes = totalFocusMinutes % 60
        return hours > 0 ? "\(hours)h \(minutes)min" : "\(minutes) min"
    }

    var levelProgress: Double {
        GamificationLogic.levelProgress(forXP: xp)
    }

    var xpInLevel: Int {
        xp - GamificationLogic.xpThreshold(toReachLevel: level)
    }

    var xpLevelSpan: Int {
        GamificationLogic.xpThreshold(toReachLevel: level + 1)
            - GamificationLogic.xpThreshold(toReachLevel: level)
    }

    /// Fixed floor keeps the chart readable when everything is zero.
    var weeklyDomainMax: Int {
        max(60, weekly.map(\.minutes).max() ?? 0)
    }

    func subjectFraction(_ item: SubjectMinutes) -> Double {
        guard let top = subjects.map(\.minutes).max(), top > 0 else { return 0 }
        return Double(item.minutes) / Double(top)
    }

    // MARK: - Loading

    func refresh() {
        guard
            let stats = try? userStatsRepository.fetchOrCreate(),
            let profile = try? userProfileRepository.fetchOrCreate(),
            let wallet = try? walletRepository.fetchOrCreateWallet()
        else { return }

        totalFocusMinutes = stats.totalFocusMinutes
        totalSessions = stats.totalSessions
        currentStreak = stats.currentStreak
        longestStreak = stats.longestStreak
        level = profile.level
        xp = profile.xp
        coins = wallet.coins

        let subjectStats = (try? subjectStatRepository.fetchAll()) ?? []
        subjects = subjectStats
            .compactMap { stat in
                guard let subject = stat.subject, stat.focusMinutes > 0 else { return nil }
                return SubjectMinutes(subject: subject, minutes: stat.focusMinutes)
            }
            .sorted { $0.minutes > $1.minutes }

        let now = Date.now
        let todayStart = calendar.startOfDay(for: now)
        if let windowStart = calendar.date(byAdding: .day, value: -6, to: todayStart),
           let windowEnd = calendar.date(byAdding: .day, value: 1, to: todayStart) {
            let sessions = (try? focusRepository.completedSessions(
                in: DateInterval(start: windowStart, end: windowEnd)
            )) ?? []
            weekly = StatsAggregator.dailyMinutes(from: sessions, endingOn: now, calendar: calendar)
        }
    }
}
