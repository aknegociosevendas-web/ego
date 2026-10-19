import Foundation
import Testing
import SwiftData
@testable import EGO

@MainActor
struct PhraseSeedServiceTests {
    /// Container returned so it outlives the repository's context (golden
    /// rule #5: a dropped ModelContainer traps SwiftData).
    func makeStack() throws -> (ModelContainer, NotificationTemplateRepository, PhraseSeedService) {
        let container = try PersistenceController.makeInMemoryContainer()
        let repository = SwiftDataNotificationTemplateRepository(container: container)
        let defaults = UserDefaults(suiteName: "test.\(UUID().uuidString)")!
        return (container, repository, PhraseSeedService(repository: repository, defaults: defaults))
    }

    func catalog(version: Int, text: String = "Bora?", weight: Double = 1.0) -> PhraseSeedService.Catalog {
        PhraseSeedService.Catalog(version: version, phrases: [
            .init(id: "cb-001", text: text, category: "comeback", weight: weight),
            .init(id: "gm-001", text: "Foco.", category: "generic", weight: 1.0),
        ])
    }

    @Test func bundledCatalogSeedsTwoHundredPhrases() throws {
        let (container, repository, service) = try makeStack()
        defer { withExtendedLifetime(container) {} }

        // Unit tests run hosted in the app, so Bundle.main carries the JSON.
        service.seedIfNeeded()

        let total = try NotificationCategory.allCases
            .flatMap { try repository.templates(category: $0.rawValue) }
        #expect(total.count == 200)
        #expect(total.allSatisfy { $0.phrase?.isEmpty == false })
        // Promoted phrases carry the 1.5 weight.
        #expect(try repository.template(key: "cb-001")?.weight == 1.5)
        #expect(try repository.template(key: "cb-002")?.weight == 1.0)
    }

    @Test func seedIsIdempotentPerVersion() throws {
        let (container, repository, service) = try makeStack()
        defer { withExtendedLifetime(container) {} }

        service.seed(catalog: catalog(version: 1))
        service.seed(catalog: catalog(version: 1, text: "Mudou!"))

        #expect(try repository.templates(category: "comeback").count == 1)
        // Same version: second pass is a no-op.
        #expect(try repository.template(key: "cb-001")?.phrase == "Bora?")
    }

    @Test func versionBumpUpdatesTextAndWeightPreservingLastUsedAt() throws {
        let (container, repository, service) = try makeStack()
        defer { withExtendedLifetime(container) {} }
        service.seed(catalog: catalog(version: 1))
        let used = Date.now.addingTimeInterval(-3_600)
        try repository.template(key: "cb-001")?.lastUsedAt = used
        try repository.save()

        service.seed(catalog: catalog(version: 2, text: "Novo texto", weight: 1.5))

        let updated = try repository.template(key: "cb-001")
        #expect(updated?.phrase == "Novo texto")
        #expect(updated?.weight == 1.5)
        #expect(updated?.lastUsedAt == used)
        // No duplicate row was created.
        #expect(try repository.templates(category: "comeback").count == 1)
    }
}
