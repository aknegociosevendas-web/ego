import Foundation
import SwiftData

/// Repertório flashcard (docs/03, F-08): a curated argument (dado, citação,
/// fato histórico, lei…) the student can browse and drill via the SM-2 queue.
@Model
final class EssayFlashcard {
    var id: UUID = UUID()
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now

    /// Stable seed key for idempotent upserts (no unique constraint; dedupe
    /// is logic-level, mirroring `Question.externalId`).
    var externalId: String?
    var front: String?
    var back: String?
    var theme: String?

    @Relationship(inverse: \ReviewItem.flashcard)
    var reviewItems: [ReviewItem]?

    init(front: String? = nil, back: String? = nil, theme: String? = nil) {
        self.front = front
        self.back = back
        self.theme = theme
    }
}
