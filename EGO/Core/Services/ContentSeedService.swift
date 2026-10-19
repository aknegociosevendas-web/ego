import Foundation

/// First-launch content seeding (docs/08 pipeline): bundled question pack +
/// repertório pack (both validated) + the ENEM essay template. Idempotent —
/// upserts by key.
@MainActor
final class ContentSeedService {
    private let questionRepository: QuestionRepository
    private let essayRepository: EssayRepository
    private let flashcardRepository: EssayFlashcardRepository
    private let calendar: Calendar

    init(
        questionRepository: QuestionRepository,
        essayRepository: EssayRepository,
        flashcardRepository: EssayFlashcardRepository,
        calendar: Calendar = .current
    ) {
        self.questionRepository = questionRepository
        self.essayRepository = essayRepository
        self.flashcardRepository = flashcardRepository
        self.calendar = calendar
    }

    func seedIfNeeded(bundle: Bundle = .main) {
        seedQuestions(bundle: bundle)
        seedRepertorio(bundle: bundle)
        _ = try? essayRepository.seedTemplateIfNeeded(
            key: EssayTemplateCatalog.enemKey,
            title: EssayTemplateCatalog.enemTitle,
            rubricKey: EssayRubricCatalog.enemKey,
            sections: EssayTemplateCatalog.enemSections
        )
    }

    private func seedRepertorio(bundle: Bundle) {
        guard
            let url = bundle.url(forResource: "repertorio-seed", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let pack = try? RepertorioPackImporter.decode(data)
        else { return }
        guard RepertorioPackImporter.validate(pack).isEmpty else {
            #if DEBUG
            print("⚠️ repertorio-seed.json failed validation; skipping seed")
            #endif
            return
        }
        _ = try? flashcardRepository.upsert(pack.flashcards)
    }

    private func seedQuestions(bundle: Bundle) {
        guard
            let url = bundle.url(forResource: "questions-seed", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let pack = try? QuestionPackImporter.decode(data)
        else { return }
        let currentYear = calendar.component(.year, from: .now)
        guard QuestionPackImporter.validate(pack, currentYear: currentYear).isEmpty else {
            #if DEBUG
            print("⚠️ questions-seed.json failed validation; skipping seed")
            #endif
            return
        }
        _ = try? questionRepository.upsert(pack.questions)
    }
}
