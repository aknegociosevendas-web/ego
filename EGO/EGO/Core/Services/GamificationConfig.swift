import Foundation

/// Single source for every tunable gamification rate (docs/07 §10).
/// Balancing happens here, never inline in services.
nonisolated struct GamificationConfig: Sendable, Equatable {
    /// XP per focused minute (docs/07 §2).
    var xpPerFocusMinute: Int = 1
    /// Flat XP bonus per completed session (docs/07 §2).
    var xpPerCompletedSession: Int = 10
    /// Coins per completed session (not specced in docs — tunable placeholder).
    var coinsPerCompletedSession: Int = 5
    /// Anti-grinding daily coin cap (docs/07 §3).
    var dailyCoinCap: Int = 50
    /// Local hour from which an unqualified day puts the streak "at risk"
    /// (mascot turns worried, docs/07 §4). Not specced — tunable placeholder.
    var streakRiskHour: Int = 20
    /// Streak milestones that award a freeze (docs/07 §4). Values not specced.
    var freezeMilestones: [Int] = [3, 7, 14, 30, 60, 100, 180, 365]
    /// Max freezes a user can hold at once.
    var maxFreezes: Int = 2
    /// Coin price of one freeze (docs/07 §3 "buyable with coins").
    var freezePriceCoins: Int = 30
    /// XP bonus when a topic goal completes (docs/07 §2).
    var xpPerGoalCompleted: Int = 40
    /// XP per correct question (docs/07 §2).
    var xpPerCorrectQuestion: Int = 3
    /// XP per finished essay (docs/07 §2).
    var xpPerEssayFinished: Int = 50
    /// Soft-focus honor window: leaving the app longer than this during a
    /// running focus abandons the session (docs/06 §7). Tunable placeholder.
    var softFocusGraceSeconds: TimeInterval = 30

    static let standard = GamificationConfig()
}
