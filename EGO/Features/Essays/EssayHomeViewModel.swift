import Foundation
import Observation

/// F-08 home state: the ENEM template + draft list.
@MainActor
@Observable
final class EssayHomeViewModel {
    private let essayRepository: EssayRepository

    private(set) var template: EssayTemplate?
    private(set) var drafts: [EssayDraft] = []

    init(essayRepository: EssayRepository) {
        self.essayRepository = essayRepository
    }

    func refresh() {
        template = try? essayRepository.templates()
            .first { $0.key == EssayTemplateCatalog.enemKey }
        drafts = (try? essayRepository.drafts()) ?? []
    }

    func newDraft() -> EssayDraft? {
        let draft = try? essayRepository.createDraft(template: template, title: nil)
        refresh()
        return draft
    }

    func delete(_ draft: EssayDraft) {
        try? essayRepository.delete(draft)
        refresh()
    }
}
