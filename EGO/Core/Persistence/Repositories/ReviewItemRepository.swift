import Foundation

/// Persistence boundary for the SM-2 review queue (F-07).
@MainActor
protocol ReviewItemRepository: AnyObject {
    func item(for question: Question) throws -> ReviewItem?
    func fetchOrCreate(for question: Question) throws -> ReviewItem
    /// Question items due on or before the end of `date`'s day.
    func dueItems(on date: Date) throws -> [ReviewItem]

    // Repertório flashcards share the SM-2 queue (F-08).
    func item(for flashcard: EssayFlashcard) throws -> ReviewItem?
    func fetchOrCreate(for flashcard: EssayFlashcard) throws -> ReviewItem
    /// Flashcard items due on or before the end of `date`'s day.
    func dueFlashcards(on date: Date) throws -> [ReviewItem]

    func save() throws
}
