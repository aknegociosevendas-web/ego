import Foundation
import Testing
import SwiftData
@testable import EGO

@MainActor
struct MotivationalPhraseSelectorTests {
    /// The container must stay alive for the repository's context — a
    /// dropped ModelContainer traps SwiftData on the next fetch (CLAUDE.md
    /// golden rule #5).
    func makeRepository() throws -> (ModelContainer, NotificationTemplateRepository) {
        let container = try PersistenceController.makeInMemoryContainer()
        return (container, SwiftDataNotificationTemplateRepository(container: container))
    }

    func seed(
        _ repository: NotificationTemplateRepository,
        _ entries: [(key: String, weight: Double, lastUsedAt: Date?)]
    ) throws {
        for entry in entries {
            try repository.upsert(
                key: entry.key,
                phrase: "Frase \(entry.key)",
                category: NotificationCategory.generic.rawValue,
                weight: entry.weight
            )
            if let used = entry.lastUsedAt {
                try repository.template(key: entry.key)?.lastUsedAt = used
            }
        }
        try repository.save()
    }

    @Test func recentlyUsedPhrasesAreFilteredOut() throws {
        let (container, repository) = try makeRepository()
        defer { withExtendedLifetime(container) {} }
        try seed(repository, [
            ("gm-a", 1.0, Date.now.addingTimeInterval(-86_400)),  // 1 day ago
            ("gm-b", 1.0, nil),
        ])
        let selector = MotivationalPhraseSelector(repository: repository)

        let picked = try selector.select(for: .generic)

        #expect(picked?.key == "gm-b")
    }

    @Test func phrasesOlderThanFourteenDaysAreEligibleAgain() throws {
        let (container, repository) = try makeRepository()
        defer { withExtendedLifetime(container) {} }
        try seed(repository, [
            ("gm-a", 1.0, Date.now.addingTimeInterval(-15 * 86_400)),
            ("gm-b", 1.0, Date.now.addingTimeInterval(-1 * 86_400)),
        ])
        let selector = MotivationalPhraseSelector(repository: repository)

        let picked = try selector.select(for: .generic)

        #expect(picked?.key == "gm-a")
    }

    @Test func exhaustedPoolFallsBackToEveryPhrase() throws {
        let (container, repository) = try makeRepository()
        defer { withExtendedLifetime(container) {} }
        try seed(repository, [
            ("gm-a", 1.0, Date.now.addingTimeInterval(-3_600)),
            ("gm-b", 1.0, Date.now.addingTimeInterval(-7_200)),
        ])
        let selector = MotivationalPhraseSelector(repository: repository)

        let picked = try selector.select(for: .generic)

        #expect(picked != nil)
    }

    @Test func selectionStampsLastUsedAt() throws {
        let (container, repository) = try makeRepository()
        defer { withExtendedLifetime(container) {} }
        try seed(repository, [("gm-a", 1.0, nil)])
        let selector = MotivationalPhraseSelector(repository: repository)

        let picked = try selector.select(for: .generic)

        #expect(picked?.lastUsedAt != nil)
    }

    @Test func emptyCategoryReturnsNil() throws {
        let (container, repository) = try makeRepository()
        defer { withExtendedLifetime(container) {} }
        let selector = MotivationalPhraseSelector(repository: repository)

        #expect(try selector.select(for: .milestone) == nil)
    }

    @Test func weightedRandomHonorsBoundaries() throws {
        // Two candidates, weights 1 and 3 (key-sorted: gm-a then gm-b): the
        // pick flips exactly at target 1.0 of the 0..<4 range.
        for (roll, expected) in [(0.5, "gm-a"), (1.5, "gm-b"), (3.9, "gm-b")] {
            let (container, repository) = try makeRepository()
        defer { withExtendedLifetime(container) {} }
            try seed(repository, [("gm-a", 1.0, nil), ("gm-b", 3.0, nil)])
            let selector = MotivationalPhraseSelector(
                repository: repository,
                random: { _ in roll }
            )
            #expect(try selector.select(for: .generic)?.key == expected)
        }
    }

    @Test func weightedRandomConvergesToTheExpectedDistribution() throws {
        let (container, repository) = try makeRepository()
        defer { withExtendedLifetime(container) {} }
        try seed(repository, [("gm-a", 1.0, nil), ("gm-b", 3.0, nil)])
        // Seeded LCG so the distribution check is deterministic.
        var state: UInt64 = 42
        let selector = MotivationalPhraseSelector(
            repository: repository,
            random: { upperBound in
                state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
                return Double(state >> 11) / Double(1 << 53) * upperBound
            }
        )

        var bCount = 0
        for _ in 0..<400 {
            // Reset usage so the cooldown never interferes with the sampling.
            try repository.template(key: "gm-a")?.lastUsedAt = nil
            try repository.template(key: "gm-b")?.lastUsedAt = nil
            try repository.save()
            if try selector.select(for: .generic)?.key == "gm-b" { bCount += 1 }
        }

        // Expected share 75%; allow generous slack for the sample size.
        #expect(bCount > 240)
        #expect(bCount < 360)
    }
}
