import Foundation

/// Repertório spaced-repetition (F-08): self-graded flashcard reviews driven
/// by `SM2Logic`, sharing the `ReviewItem` queue with the question bank.
/// No XP/stats (docs/07 doesn't rate repertório) — the mascot reaction fires
/// from the study view model when a session finishes.
@MainActor
final class FlashcardReviewService {
    private let reviewItemRepository: ReviewItemRepository
    private let calendar: Calendar

    init(reviewItemRepository: ReviewItemRepository, calendar: Calendar = .current) {
        self.reviewItemRepository = reviewItemRepository
        self.calendar = calendar
    }

    /// Self-graded review (quality 0–5): advances the card's SM-2 state and
    /// reschedules its due date.
    func recordReview(flashcard: EssayFlashcard, grade: Int, at date: Date = .now) throws {
        let item = try reviewItemRepository.fetchOrCreate(for: flashcard)
        let next = SM2Logic.review(
            SM2Logic.State(
                easeFactor: item.easeFactor,
                interval: item.interval,
                repetitions: item.repetitions
            ),
            grade: grade
        )
        item.easeFactor = next.easeFactor
        item.interval = next.interval
        item.repetitions = next.repetitions
        item.lastGrade = grade
        item.dueDate = SM2Logic.dueDate(after: next, reviewedOn: date, calendar: calendar)
        item.updatedAt = date
        try reviewItemRepository.save()
    }

    /// Adds a card to the SM-2 queue (due tomorrow) without grading it — the
    /// "adicionar à revisão" action while browsing.
    func enqueue(_ flashcard: EssayFlashcard, at date: Date = .now) throws {
        let item = try reviewItemRepository.fetchOrCreate(for: flashcard)
        if item.dueDate == nil {
            item.dueDate = calendar.date(
                byAdding: .day, value: 1, to: calendar.startOfDay(for: date)
            )
            item.updatedAt = date
        }
        try reviewItemRepository.save()
    }
}
