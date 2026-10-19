import Foundation

/// Persistence boundary for repertório flashcards (F-08).
@MainActor
protocol EssayFlashcardRepository: AnyObject {
    func fetchAll() throws -> [EssayFlashcard]
    /// Cards for a theme, or all when `theme` is nil.
    func flashcards(theme: String?) throws -> [EssayFlashcard]
    /// Distinct themes present in the bank, sorted.
    func themes() throws -> [String]
    /// Upsert by `externalId` (dedupe is logic-level — no unique constraints).
    /// Returns how many new cards were inserted.
    @discardableResult
    func upsert(_ items: [RepertorioPackImporter.Item]) throws -> Int
    func save() throws
}
