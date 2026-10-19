import Foundation
import SwiftData

/// Question-bank item (docs/03, F-07). Content comes from validated packs
/// (ENEM/INEP public items or EGO originals — docs/08); options are stored
/// as Data for CloudKit friendliness. Dedupe is by `externalId` in the
/// importer (no unique constraints allowed).
@Model
final class Question {
    var id: UUID = UUID()
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now

    var externalId: String?
    var exam: String?
    var year: Int?
    var subject: String?
    var topic: String?
    /// 1 = easy … 3 = hard.
    var difficulty: Int?
    var statement: String?
    var optionsData: Data?
    var correctIndex: Int?
    var explanation: String?
    var source: String?
    var licenseNote: String?

    @Relationship(inverse: \QuestionAttempt.question)
    var attempts: [QuestionAttempt]?
    @Relationship(inverse: \ReviewItem.question)
    var reviewItems: [ReviewItem]?

    init() {}

    var options: [String] {
        get {
            guard let optionsData else { return [] }
            return (try? JSONDecoder().decode([String].self, from: optionsData)) ?? []
        }
        set {
            optionsData = try? JSONEncoder().encode(newValue)
        }
    }
}
