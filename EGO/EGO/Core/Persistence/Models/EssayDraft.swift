import Foundation
import SwiftData

/// One essay draft (docs/03, F-08). Finalizing records self-score against
/// the rubric and feeds stats/XP.
@Model
final class EssayDraft {
    var id: UUID = UUID()
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now

    var title: String?
    var bodyText: String?
    var wordCount: Int = 0
    /// Rubric total (0–1000 for ENEM).
    var selfScore: Int?
    /// Per-competency scores serialized as [Int].
    var competencyScoresData: Data?
    var finishedAt: Date?

    /// Inverse lives on `EssayTemplate.drafts`.
    var template: EssayTemplate?

    init(title: String? = nil) {
        self.title = title
    }

    var competencyScores: [Int] {
        get {
            guard let competencyScoresData else { return [] }
            return (try? JSONDecoder().decode([Int].self, from: competencyScoresData)) ?? []
        }
        set {
            competencyScoresData = try? JSONEncoder().encode(newValue)
        }
    }
}
