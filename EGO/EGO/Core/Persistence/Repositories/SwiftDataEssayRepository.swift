import Foundation
import SwiftData

@MainActor
final class SwiftDataEssayRepository: EssayRepository {
    private let context: ModelContext

    init(container: ModelContainer) {
        self.context = container.mainContext
    }

    func templates() throws -> [EssayTemplate] {
        try context.fetch(FetchDescriptor<EssayTemplate>())
            .sorted { ($0.key ?? "") < ($1.key ?? "") }
    }

    @discardableResult
    func seedTemplateIfNeeded(
        key: String,
        title: String,
        rubricKey: String,
        sections: [EssaySection]
    ) throws -> EssayTemplate {
        if let existing = try templates().first(where: { $0.key == key }) {
            return existing
        }
        let template = EssayTemplate(key: key, title: title, rubricKey: rubricKey)
        template.sections = sections
        context.insert(template)
        try context.save()
        return template
    }

    func drafts() throws -> [EssayDraft] {
        try context.fetch(FetchDescriptor<EssayDraft>())
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    @discardableResult
    func createDraft(template: EssayTemplate?, title: String?) throws -> EssayDraft {
        let draft = EssayDraft(title: title)
        draft.template = template
        context.insert(draft)
        try context.save()
        return draft
    }

    func delete(_ draft: EssayDraft) throws {
        context.delete(draft)
        try context.save()
    }

    func save() throws {
        try context.save()
    }
}
