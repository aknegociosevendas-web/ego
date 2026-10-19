import Foundation
import Observation

/// F-08 repertório study session: one flip-card at a time, self-graded into
/// the SM-2 queue. Identifiable so the view can present it. The mascot
/// celebrates when the session finishes (repertório mascot hook).
@MainActor
@Observable
final class RepertorioStudyViewModel: Identifiable {
    /// SM-2 grades surfaced as four buttons (docs/08 §1).
    enum Grade: Int, CaseIterable {
        case errei = 2   // <3 → repetitions reset, review again tomorrow
        case dificil = 3
        case bom = 4
        case facil = 5
    }

    let id = UUID()

    private let reviewService: FlashcardReviewService
    private let mascotEvents: MascotEventCenter
    private(set) var cards: [EssayFlashcard]
    private(set) var index = 0
    private(set) var isRevealed = false
    private(set) var reviewedCount = 0

    init(
        cards: [EssayFlashcard],
        reviewService: FlashcardReviewService,
        mascotEvents: MascotEventCenter
    ) {
        self.cards = cards.shuffled()
        self.reviewService = reviewService
        self.mascotEvents = mascotEvents
    }

    var current: EssayFlashcard? {
        cards.indices.contains(index) ? cards[index] : nil
    }

    var total: Int { cards.count }
    var isFinished: Bool { index >= cards.count }

    func reveal() { isRevealed = true }

    func grade(_ grade: Grade) {
        guard isRevealed, let card = current else { return }
        try? reviewService.recordReview(flashcard: card, grade: grade.rawValue)
        reviewedCount += 1
        index += 1
        isRevealed = false
        // Repertório session complete → mascot celebrates (F-08 hook).
        if isFinished {
            mascotEvents.sessionCompleted()
        }
    }
}
