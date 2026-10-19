import Foundation

/// Persistence boundary for essay templates and drafts (F-08).
@MainActor
protocol EssayRepository: AnyObject {
    func templates() throws -> [EssayTemplate]
    @discardableResult
    func seedTemplateIfNeeded(
        key: String,
        title: String,
        rubricKey: String,
        sections: [EssaySection]
    ) throws -> EssayTemplate
    func drafts() throws -> [EssayDraft]
    @discardableResult
    func createDraft(template: EssayTemplate?, title: String?) throws -> EssayDraft
    func delete(_ draft: EssayDraft) throws
    func save() throws
}
