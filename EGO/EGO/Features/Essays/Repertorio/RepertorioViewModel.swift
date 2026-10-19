import Foundation
import Observation

/// F-08 repertório browse state: the flashcard bank filtered by tema, plus
/// today's due-review count and a "adicionar à revisão" action.
@MainActor
@Observable
final class RepertorioViewModel {
    private let flashcardRepository: EssayFlashcardRepository
    private let reviewItemRepository: ReviewItemRepository
    private let reviewService: FlashcardReviewService

    var selectedTheme: String?
    private(set) var allCards: [EssayFlashcard] = []
    private(set) var dueCards: [EssayFlashcard] = []
    /// Cards already sitting in the SM-2 queue (any due date), for badge state.
    private(set) var queuedCardIDs: Set<UUID> = []

    init(
        flashcardRepository: EssayFlashcardRepository,
        reviewItemRepository: ReviewItemRepository,
        reviewService: FlashcardReviewService
    ) {
        self.flashcardRepository = flashcardRepository
        self.reviewItemRepository = reviewItemRepository
        self.reviewService = reviewService
    }

    var themes: [String] { (try? flashcardRepository.themes()) ?? [] }

    var filtered: [EssayFlashcard] {
        guard let selectedTheme else { return allCards }
        return allCards.filter { $0.theme == selectedTheme }
    }

    func refresh(now: Date = .now) {
        allCards = (try? flashcardRepository.fetchAll()) ?? []
        dueCards = ((try? reviewItemRepository.dueFlashcards(on: now)) ?? [])
            .compactMap(\.flashcard)
        queuedCardIDs = Set(allCards.filter { card in
            (card.reviewItems ?? []).contains { $0.dueDate != nil }
        }.map(\.id))
        if let theme = selectedTheme, !themes.contains(theme) {
            selectedTheme = nil
        }
    }

    func isQueued(_ card: EssayFlashcard) -> Bool { queuedCardIDs.contains(card.id) }

    func addToReview(_ card: EssayFlashcard, now: Date = .now) {
        try? reviewService.enqueue(card, at: now)
        refresh(now: now)
    }
}
