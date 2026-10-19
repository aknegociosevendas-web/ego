import Foundation
import SwiftData

/// SM-2 spaced-repetition state (docs/03, F-07) for a question or, later,
/// a repertório flashcard.
@Model
final class ReviewItem {
    var id: UUID = UUID()
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now

    var easeFactor: Double = 2.5
    /// Days until the next review.
    var interval: Int = 0
    var repetitions: Int = 0
    var dueDate: Date?
    var lastGrade: Int?

    /// Inverses live on `Question.reviewItems` / `EssayFlashcard.reviewItems`.
    var question: Question?
    var flashcard: EssayFlashcard?

    init() {}
}
