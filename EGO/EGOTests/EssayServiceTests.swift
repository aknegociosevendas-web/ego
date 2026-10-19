import Foundation
import Testing
@testable import EGO

@MainActor
struct EssayServiceTests {
    func makeContext() throws -> DIContainer {
        let container = try PersistenceController.makeInMemoryContainer()
        return DIContainer(modelContainer: container)
    }

    @Test func wordCountSplitsOnWhitespaceAndNewlines() {
        #expect(EssayService.wordCount(of: "") == 0)
        #expect(EssayService.wordCount(of: "uma  redação\nnota mil ") == 4)
    }

    @Test func finalizeScoresStatsXPAndMascot() throws {
        let di = try makeContext()
        di.contentSeedService.seedIfNeeded()
        let template = try di.essayRepository.templates()[0]
        let draft = try di.essayRepository.createDraft(template: template, title: "Teste")
        draft.bodyText = "Uma redação curta de teste com oito palavras aqui."

        let total = try di.essayService.finalize(
            draft, competencyScores: [160, 120, 160, 120, 200]
        )

        #expect(total == 760)
        #expect(draft.selfScore == 760)
        #expect(draft.competencyScores == [160, 120, 160, 120, 200])
        #expect(draft.finishedAt != nil)
        #expect(draft.wordCount == 9)

        let stats = try di.userStatsRepository.fetchOrCreate()
        #expect(stats.essaysFinished == 1)
        #expect(try di.userProfileRepository.fetchOrCreate().xp == 50)
        #expect(di.mascotEvents.state == .happy)
    }

    @Test func seedIsIdempotent() throws {
        let di = try makeContext()
        di.contentSeedService.seedIfNeeded()
        di.contentSeedService.seedIfNeeded()

        #expect(try di.essayRepository.templates().count == 1)
        let template = try di.essayRepository.templates()[0]
        #expect(template.key == EssayTemplateCatalog.enemKey)
        #expect(template.sections.count == 4)

        let questions = try di.questionRepository.fetchAll()
        #expect(questions.count == 12)
        #expect(Set(questions.compactMap(\.externalId)).count == 12)
    }
}
