import Foundation
import Testing
@testable import EGO

@MainActor
struct RepertorioTests {
    func makeContext() throws -> DIContainer {
        let container = try PersistenceController.makeInMemoryContainer()
        return DIContainer(modelContainer: container)
    }

    // MARK: - Seeding

    @Test func seedLoadsRepertorioCardsIdempotently() throws {
        let di = try makeContext()
        di.contentSeedService.seedIfNeeded()
        di.contentSeedService.seedIfNeeded()

        let cards = try di.flashcardRepository.fetchAll()
        #expect(cards.count == 8)
        #expect(Set(cards.compactMap(\.externalId)).count == 8)
        // Themes drive the browse filter.
        #expect(try di.flashcardRepository.themes().contains("Educação"))
    }

    @Test func packImporterValidatesShape() {
        let good = RepertorioPackImporter.Pack(
            version: 1, pack: "t",
            flashcards: [.init(externalId: "a", theme: "T", front: "F", back: "B")]
        )
        #expect(RepertorioPackImporter.validate(good).isEmpty)

        let bad = RepertorioPackImporter.Pack(
            version: 1, pack: "t",
            flashcards: [
                .init(externalId: "a", theme: "", front: "F", back: "B"),
                .init(externalId: "a", theme: "T", front: "F", back: ""),
            ]
        )
        #expect(!RepertorioPackImporter.validate(bad).isEmpty)
    }

    // MARK: - SM-2 scheduling

    @Test func recordReviewAdvancesSM2State() throws {
        let di = try makeContext()
        di.contentSeedService.seedIfNeeded()
        let card = try di.flashcardRepository.fetchAll()[0]
        let day0 = Date(timeIntervalSince1970: 1_000_000)

        try di.flashcardReviewService.recordReview(flashcard: card, grade: 5, at: day0)

        let item = try #require(try di.reviewItemRepository.item(for: card))
        #expect(item.repetitions == 1)
        #expect(item.interval == 1)
        #expect(item.lastGrade == 5)
        #expect(item.easeFactor > 2.5) // grade 5 raises ease
        #expect(item.dueDate != nil)
    }

    @Test func enqueuedCardBecomesDueNextDayAndStaysOutOfQuestionQueue() throws {
        let di = try makeContext()
        di.contentSeedService.seedIfNeeded()
        let card = try di.flashcardRepository.fetchAll()[0]
        let today = Date(timeIntervalSince1970: 1_000_000)
        let tomorrow = today.addingTimeInterval(86_400)

        try di.flashcardReviewService.enqueue(card, at: today)

        let dueFlash = try di.reviewItemRepository.dueFlashcards(on: tomorrow)
        #expect(dueFlash.compactMap(\.flashcard).contains { $0.id == card.id })
        // Flashcards must not leak into the question review queue.
        #expect(try di.reviewItemRepository.dueItems(on: tomorrow).isEmpty)
    }

    // MARK: - Study session mascot hook

    @Test func finishingStudySessionCelebratesWithMascot() throws {
        let di = try makeContext()
        di.contentSeedService.seedIfNeeded()
        let cards = Array(try di.flashcardRepository.fetchAll().prefix(2))
        let vm = di.makeRepertorioStudyViewModel(cards: cards)

        vm.reveal()
        vm.grade(.bom)
        #expect(!vm.isFinished)
        #expect(di.mascotEvents.state == .idle) // not finished yet

        vm.reveal()
        vm.grade(.facil)
        #expect(vm.isFinished)
        #expect(vm.reviewedCount == 2)
        #expect(di.mascotEvents.state == .happy) // repertório session complete
    }

    @Test func browseViewModelSurfacesDueCountAndQueuedState() throws {
        let di = try makeContext()
        di.contentSeedService.seedIfNeeded()
        let vm = di.makeRepertorioViewModel()
        let card = try di.flashcardRepository.fetchAll()[0]

        vm.refresh()
        #expect(!vm.isQueued(card))

        vm.addToReview(card)
        #expect(vm.isQueued(card))
    }
}
