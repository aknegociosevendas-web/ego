import Foundation

/// Pure "streak at risk?" check (docs/07 §4): the streak is only saveable —
/// and worth worrying about — while the last qualified day is yesterday and
/// today hasn't qualified yet. Available freezes don't silence the worry;
/// they're a safety net, not a reason to skip studying.
nonisolated enum StreakRiskLogic {
    static func isAtRisk(
        current: Int,
        lastQualifiedDay: Date?,
        now: Date,
        calendar: Calendar,
        riskHour: Int
    ) -> Bool {
        guard current > 0, let last = lastQualifiedDay else { return false }
        guard let yesterday = calendar.date(
            byAdding: .day,
            value: -1,
            to: calendar.startOfDay(for: now)
        ) else { return false }
        guard calendar.isDate(last, inSameDayAs: yesterday) else { return false }
        return calendar.component(.hour, from: now) >= riskHour
    }
}
