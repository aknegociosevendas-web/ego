import Foundation

/// Picks the phrase a notification (or card) should carry (slice 7).
@MainActor
protocol MotivationalPhraseSelectorProtocol: AnyObject {
    func select(for category: NotificationCategory) throws -> NotificationTemplate?
}

/// Weighted random over the category pool, skipping phrases used in the last
/// 14 days (unless that empties the pool), stamping `lastUsedAt` on the pick.
@MainActor
final class MotivationalPhraseSelector: MotivationalPhraseSelectorProtocol {
    static let reuseCooldown: TimeInterval = 14 * 86_400

    private let repository: NotificationTemplateRepository
    private let now: () -> Date
    /// Injectable randomness so tests can seed the distribution.
    private var random: (_ upperBound: Double) -> Double

    init(
        repository: NotificationTemplateRepository,
        now: @escaping () -> Date = { .now },
        random: @escaping (_ upperBound: Double) -> Double = { Double.random(in: 0..<$0) }
    ) {
        self.repository = repository
        self.now = now
        self.random = random
    }

    func select(for category: NotificationCategory) throws -> NotificationTemplate? {
        let pool = try repository.templates(category: category.rawValue)
            .filter { $0.phrase?.isEmpty == false }
        guard !pool.isEmpty else { return nil }

        let cutoff = now().addingTimeInterval(-Self.reuseCooldown)
        let fresh = pool.filter { ($0.lastUsedAt ?? .distantPast) < cutoff }
        // Every phrase used within the cooldown: fall back to the full pool.
        let candidates = fresh.isEmpty ? pool : fresh

        let picked = weightedPick(from: candidates)
        picked?.lastUsedAt = now()
        try repository.save()
        return picked
    }

    private func weightedPick(from candidates: [NotificationTemplate]) -> NotificationTemplate? {
        let total = candidates.reduce(0) { $0 + max(0, $1.weight) }
        guard total > 0 else { return candidates.first }
        var target = random(total)
        for candidate in candidates {
            target -= max(0, candidate.weight)
            if target < 0 { return candidate }
        }
        return candidates.last
    }
}
