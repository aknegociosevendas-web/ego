import Foundation
import Observation

/// F-08 editor state: scaffold, live word count, drafts, finalize with rubric.
@MainActor
@Observable
final class EssayEditorViewModel {
    let draft: EssayDraft
    let startedAt = Date.now

    var title: String
    var body: String

    private let essayRepository: EssayRepository
    private let essayService: EssayService

    init(draft: EssayDraft, essayRepository: EssayRepository, essayService: EssayService) {
        self.draft = draft
        self.essayRepository = essayRepository
        self.essayService = essayService
        self.title = draft.title ?? ""
        self.body = draft.bodyText ?? ""
    }

    var wordCount: Int {
        EssayService.wordCount(of: body)
    }

    var sections: [EssaySection] {
        draft.template?.sections ?? []
    }

    var isFinished: Bool {
        draft.finishedAt != nil
    }

    var selfScore: Int? {
        draft.selfScore
    }

    func save() {
        draft.title = title.isEmpty ? nil : title
        draft.bodyText = body
        draft.wordCount = wordCount
        draft.updatedAt = .now
        try? essayRepository.save()
    }

    @discardableResult
    func finalize(scores: [Int]) -> Int? {
        save()
        return try? essayService.finalize(draft, competencyScores: scores)
    }
}
