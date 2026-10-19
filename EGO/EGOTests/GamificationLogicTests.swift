import Foundation
import Testing
@testable import EGO

struct GamificationLogicTests {
    let config = GamificationConfig.standard

    // MARK: - XP

    @Test func xpForCompletedSessionAddsMinutesAndBonus() {
        // 25 focused minutes → 25 XP + 10 session bonus.
        #expect(GamificationLogic.xpEarned(forCompletedSessionMinutes: 25, config: config) == 35)
        #expect(GamificationLogic.xpEarned(forCompletedSessionMinutes: 50, config: config) == 60)
        #expect(GamificationLogic.xpEarned(forCompletedSessionMinutes: 0, config: config) == 10)
    }

    // MARK: - Level curve (50·n·(n+1) cumulative)

    @Test func levelThresholds() {
        #expect(GamificationLogic.xpThreshold(toReachLevel: 1) == 0)
        #expect(GamificationLogic.xpThreshold(toReachLevel: 2) == 100)
        #expect(GamificationLogic.xpThreshold(toReachLevel: 3) == 300)
        #expect(GamificationLogic.xpThreshold(toReachLevel: 4) == 600)
        #expect(GamificationLogic.xpThreshold(toReachLevel: 5) == 1000)
    }

    @Test(arguments: [
        (0, 1), (1, 1), (99, 1),
        (100, 2), (299, 2),
        (300, 3), (599, 3),
        (600, 4),
        (1000, 5),
        (10_100, 14), // threshold for 15 is 50·14·15 = 10_500
        (10_500, 15),
    ])
    func levelForXP(xp: Int, expected: Int) {
        #expect(GamificationLogic.level(forXP: xp) == expected)
    }

    @Test func levelNeverBelowOneForNegativeXP() {
        #expect(GamificationLogic.level(forXP: -50) == 1)
    }

    @Test(arguments: [
        (0, 0.0), (50, 0.5), (99, 0.99),
        (100, 0.0),          // just reached level 2 (span 100→300)
        (200, 0.5), (300, 0.0),
    ])
    func levelProgress(xp: Int, expected: Double) {
        #expect(abs(GamificationLogic.levelProgress(forXP: xp) - expected) < 0.0001)
    }

    // MARK: - Coins

    @Test func coinsPerSessionUntilDailyCap() {
        // Cap 50, 5/session → sessions 1–10 pay, 11th doesn't.
        #expect(GamificationLogic.coinsEarned(priorSessionsToday: 0, config: config) == 5)
        #expect(GamificationLogic.coinsEarned(priorSessionsToday: 9, config: config) == 5)
        #expect(GamificationLogic.coinsEarned(priorSessionsToday: 10, config: config) == 0)
        #expect(GamificationLogic.coinsEarned(priorSessionsToday: 99, config: config) == 0)
    }

    @Test func coinsArePartiallyPaidAtTheCapEdge() {
        var tight = GamificationConfig.standard
        tight.dailyCoinCap = 12
        // 2 prior sessions → 10 earned; only 2 coins left under the cap.
        #expect(GamificationLogic.coinsEarned(priorSessionsToday: 2, config: tight) == 2)
    }
}
