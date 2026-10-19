import Foundation
import SwiftData

/// One answer to a question (docs/03, F-07). Append-only history feeding
/// stats and accuracy per subject/topic.
@Model
final class QuestionAttempt {
    var id: UUID = UUID()
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now

    var chosenIndex: Int?
    var correct: Bool = false
    var answeredAt: Date?
    /// Seconds spent on the question.
    var timeSpent: Int = 0
    var markedForReview: Bool = false

    /// Inverse lives on `Question.attempts`.
    var question: Question?

    init(chosenIndex: Int? = nil, correct: Bool = false, answeredAt: Date? = nil, timeSpent: Int = 0) {
        self.chosenIndex = chosenIndex
        self.correct = correct
        self.answeredAt = answeredAt
        self.timeSpent = timeSpent
    }
}
