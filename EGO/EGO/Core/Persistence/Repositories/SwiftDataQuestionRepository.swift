import Foundation
import SwiftData

@MainActor
final class SwiftDataQuestionRepository: QuestionRepository {
    private let context: ModelContext

    init(container: ModelContainer) {
        self.context = container.mainContext
    }

    func fetchAll() throws -> [Question] {
        try context.fetch(FetchDescriptor<Question>())
            .sorted { ($0.externalId ?? "") < ($1.externalId ?? "") }
    }

    func questions(matching filters: QuestionFilters) throws -> [Question] {
        try fetchAll().filter { question in
            (filters.exam == nil || question.exam == filters.exam)
                && (filters.year == nil || question.year == filters.year)
                && (filters.subject == nil || question.subject == filters.subject)
                && (filters.topic == nil || question.topic == filters.topic)
                && (filters.difficulty == nil || question.difficulty == filters.difficulty)
        }
    }

    @discardableResult
    func upsert(_ items: [QuestionPackImporter.Item]) throws -> Int {
        let existingIDs = Set(try fetchAll().compactMap(\.externalId))
        var inserted = 0
        for item in items where !existingIDs.contains(item.externalId) {
            let question = Question()
            question.externalId = item.externalId
            question.exam = item.exam
            question.year = item.year
            question.subject = item.subject
            question.topic = item.topic
            question.difficulty = item.difficulty
            question.statement = item.statement
            question.options = item.options
            question.correctIndex = item.correctIndex
            question.explanation = item.explanation
            question.source = item.source
            question.licenseNote = item.licenseNote
            context.insert(question)
            inserted += 1
        }
        if inserted > 0 {
            try context.save()
        }
        return inserted
    }

    func save() throws {
        try context.save()
    }
}
