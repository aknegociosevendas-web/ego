import Foundation
import SwiftData

@MainActor
final class SwiftDataEssayFlashcardRepository: EssayFlashcardRepository {
    private let context: ModelContext

    init(container: ModelContainer) {
        self.context = container.mainContext
    }

    func fetchAll() throws -> [EssayFlashcard] {
        try context.fetch(FetchDescriptor<EssayFlashcard>())
            .sorted { ($0.externalId ?? "") < ($1.externalId ?? "") }
    }

    func flashcards(theme: String?) throws -> [EssayFlashcard] {
        guard let theme else { return try fetchAll() }
        return try fetchAll().filter { $0.theme == theme }
    }

    func themes() throws -> [String] {
        Array(Set(try fetchAll().compactMap(\.theme))).sorted()
    }

    @discardableResult
    func upsert(_ items: [RepertorioPackImporter.Item]) throws -> Int {
        let existingIDs = Set(try fetchAll().compactMap(\.externalId))
        var inserted = 0
        for item in items where !existingIDs.contains(item.externalId) {
            let card = EssayFlashcard(front: item.front, back: item.back, theme: item.theme)
            card.externalId = item.externalId
            context.insert(card)
            inserted += 1
        }
        if inserted > 0 {
            try context.save()
        }
        return inserted
    }

    func save() throws {
        try context.save()
    }
}
