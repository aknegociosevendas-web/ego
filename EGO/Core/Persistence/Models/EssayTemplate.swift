import Foundation
import SwiftData

/// Structured essay scaffold (docs/03, F-08), e.g. ENEM
/// dissertativo-argumentativo. Sections serialized as Data.
@Model
final class EssayTemplate {
    var id: UUID = UUID()
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now

    var key: String?
    var title: String?
    var structureData: Data?
    var rubricKey: String?

    @Relationship(inverse: \EssayDraft.template)
    var drafts: [EssayDraft]?

    init(key: String? = nil, title: String? = nil, rubricKey: String? = nil) {
        self.key = key
        self.title = title
        self.rubricKey = rubricKey
    }

    var sections: [EssaySection] {
        get {
            guard let structureData else { return [] }
            return (try? JSONDecoder().decode([EssaySection].self, from: structureData)) ?? []
        }
        set {
            structureData = try? JSONEncoder().encode(newValue)
        }
    }
}

/// One scaffold section with its writing hint (content data, PT-BR).
nonisolated struct EssaySection: Codable, Equatable, Sendable {
    let title: String
    let hint: String
}
