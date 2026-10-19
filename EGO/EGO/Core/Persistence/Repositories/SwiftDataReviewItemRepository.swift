import Foundation
import SwiftData

@MainActor
final class SwiftDataReviewItemRepository: ReviewItemRepository {
    private let context: ModelContext
    private let calendar: Calendar

    init(container: ModelContainer, calendar: Calendar = .current) {
        self.context = container.mainContext
        self.calendar = calendar
    }

    func item(for question: Question) throws -> ReviewItem? {
        (question.reviewItems ?? []).first
    }

    func fetchOrCreate(for question: Question) throws -> ReviewItem {
        if let existing = try item(for: question) {
            return existing
        }
        let item = ReviewItem()
        item.question = question
        context.insert(item)
        try context.save()
        return item
    }

    func dueItems(on date: Date) throws -> [ReviewItem] {
        try dueItems(on: date) { $0.question != nil }
    }

    func item(for flashcard: EssayFlashcard) throws -> ReviewItem? {
        (flashcard.reviewItems ?? []).first
    }

    func fetchOrCreate(for flashcard: EssayFlashcard) throws -> ReviewItem {
        if let existing = try item(for: flashcard) {
            return existing
        }
        let item = ReviewItem()
        item.flashcard = flashcard
        context.insert(item)
        try context.save()
        return item
    }

    func dueFlashcards(on date: Date) throws -> [ReviewItem] {
        try dueItems(on: date) { $0.flashcard != nil }
    }

    func save() throws {
        try context.save()
    }

    /// Due items (dueDate ≤ end of `date`'s day) matching `belongsToKind`.
    private func dueItems(
        on date: Date, belongsToKind: (ReviewItem) -> Bool
    ) throws -> [ReviewItem] {
        guard let dayEnd = calendar.date(
            byAdding: .day, value: 1, to: calendar.startOfDay(for: date)
        ) else { return [] }
        return try context.fetch(FetchDescriptor<ReviewItem>())
            .filter { item in
                guard belongsToKind(item), let due = item.dueDate else { return false }
                return due < dayEnd
            }
            .sorted { ($0.dueDate ?? .distantPast) < ($1.dueDate ?? .distantPast) }
    }
}
