import Foundation

/// Pure XP/level/coin math (docs/07 §2–3). No persistence, fully unit-tested.
/// `nonisolated`: pure math, opted out of the project's MainActor default.
nonisolated enum GamificationLogic {
    /// XP for a completed focus session.
    static func xpEarned(forCompletedSessionMinutes minutes: Int, config: GamificationConfig) -> Int {
        minutes * config.xpPerFocusMinute + config.xpPerCompletedSession
    }

    /// Cumulative XP required to reach `level` (docs/07 curve `50·n·(n+1)`,
    /// read as: leaving level n costs 50·n·(n+1) total XP). Level 1 starts at 0.
    static func xpThreshold(toReachLevel level: Int) -> Int {
        50 * (level - 1) * level
    }

    /// Largest level whose threshold is within `xp`.
    static func level(forXP xp: Int) -> Int {
        guard xp > 0 else { return 1 }
        // Invert the quadratic threshold, then correct float edges.
        var level = max(1, Int((1 + (1 + Double(xp) / 12.5).squareRoot()) / 2))
        while xpThreshold(toReachLevel: level + 1) <= xp { level += 1 }
        while level > 1 && xpThreshold(toReachLevel: level) > xp { level -= 1 }
        return level
    }

    /// Progress through the current level, 0…1 (XP bar on the stats screen).
    static func levelProgress(forXP xp: Int) -> Double {
        let level = level(forXP: xp)
        let floor = xpThreshold(toReachLevel: level)
        let ceiling = xpThreshold(toReachLevel: level + 1)
        guard ceiling > floor else { return 0 }
        return min(1, max(0, Double(xp - floor) / Double(ceiling - floor)))
    }

    /// Coins for one more completed session today, respecting the daily cap.
    /// `priorSessionsToday` = completed sessions already rewarded today.
    static func coinsEarned(priorSessionsToday: Int, config: GamificationConfig) -> Int {
        let alreadyEarned = priorSessionsToday * config.coinsPerCompletedSession
        return max(0, min(config.coinsPerCompletedSession, config.dailyCoinCap - alreadyEarned))
    }
}
