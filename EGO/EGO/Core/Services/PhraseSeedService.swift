import Foundation

/// Seeds/updates the motivational phrase bank from the bundled
/// `motivational-phrases.json` (slice 7). Runs when the bundled `version` is
/// newer than the persisted one: upserts by id (text/category/weight refresh,
/// `lastUsedAt` preserved), creates missing rows. Idempotent.
@MainActor
final class PhraseSeedService {
    /// Decoded shape of the bundled catalog.
    nonisolated struct Catalog: Decodable {
        struct Phrase: Decodable {
            let id: String
            let text: String
            let category: String
            let weight: Double
        }

        let version: Int
        let phrases: [Phrase]
    }

    static let versionDefaultsKey = "motivationalPhrasesSeedVersion"

    private let repository: NotificationTemplateRepository
    private let defaults: UserDefaults

    init(repository: NotificationTemplateRepository, defaults: UserDefaults = .standard) {
        self.repository = repository
        self.defaults = defaults
    }

    func seedIfNeeded(bundle: Bundle = .main) {
        guard let url = bundle.url(
            forResource: "motivational-phrases", withExtension: "json"
        ), let catalog = try? JSONDecoder().decode(
            Catalog.self, from: Data(contentsOf: url)
        ) else {
            assertionFailure("motivational-phrases.json missing or malformed")
            return
        }
        seed(catalog: catalog)
    }

    func seed(catalog: Catalog) {
        let seededVersion = defaults.integer(forKey: Self.versionDefaultsKey)
        guard catalog.version > seededVersion else { return }
        do {
            for phrase in catalog.phrases {
                try repository.upsert(
                    key: phrase.id,
                    phrase: phrase.text,
                    category: phrase.category,
                    weight: phrase.weight
                )
            }
            try repository.save()
            defaults.set(catalog.version, forKey: Self.versionDefaultsKey)
        } catch {
            // Leave the persisted version untouched so the next launch retries.
        }
    }
}
