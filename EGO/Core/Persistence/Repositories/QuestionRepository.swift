import Foundation

/// Browse/practice filters (F-07). Nil = "all".
nonisolated struct QuestionFilters: Equatable, Sendable {
    var exam: String?
    var year: Int?
    var subject: String?
    var topic: String?
    var difficulty: Int?
}

/// Persistence boundary for the question bank.
@MainActor
protocol QuestionRepository: AnyObject {
    func fetchAll() throws -> [Question]
    func questions(matching filters: QuestionFilters) throws -> [Question]
    /// Upsert by `externalId` (dedupe is logic-level — no unique constraints).
    /// Returns how many new questions were inserted.
    @discardableResult
    func upsert(_ items: [QuestionPackImporter.Item]) throws -> Int
    func save() throws
}
