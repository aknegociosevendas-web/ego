import Foundation
import Testing
@testable import EGO

@MainActor
struct FocusRepositoryTests {
    @Test func inMemoryRepositorySavesAndFetches() throws {
        let repository = InMemoryFocusRepository()
        let session = FocusSession(plannedMinutes: 25)

        try repository.save(session)

        #expect(try repository.fetchAll().count == 1)
        #expect(try repository.fetch(id: session.id)?.id == session.id)
    }

    @Test func inMemoryRepositoryDeletes() throws {
        let repository = InMemoryFocusRepository()
        let session = FocusSession()

        try repository.save(session)
        try repository.delete(session)

        #expect(try repository.fetchAll().isEmpty)
    }

    @Test func swiftDataRepositorySavesAndFetches() throws {
        let container = try PersistenceController.makeInMemoryContainer()
        let repository = SwiftDataFocusRepository(container: container)
        let session = FocusSession(plannedMinutes: 50, subject: "Matemática")

        try repository.save(session)

        #expect(try repository.fetchAll().count == 1)
        let fetched = try repository.fetch(id: session.id)
        #expect(fetched?.plannedMinutes == 50)
        #expect(fetched?.subject == "Matemática")
    }
}
