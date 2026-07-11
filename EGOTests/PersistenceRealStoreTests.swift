import Foundation
import SwiftData
import Testing
@testable import EGO

/// CLAUDE.md rule: after any schema change, exercise a real on-disk
/// ModelContainer (not just in-memory) so store-level issues surface here
/// instead of at app launch.
@MainActor
struct PersistenceRealStoreTests {
    @Test func fullSchemaRoundTripsOnARealStore() throws {
        let url = URL.temporaryDirectory
            .appending(path: "ego-schema-test-\(UUID().uuidString).store")
        defer { try? FileManager.default.removeItem(at: url) }

        let configuration = ModelConfiguration(schema: PersistenceController.schema, url: url)
        let container = try ModelContainer(
            for: PersistenceController.schema, configurations: [configuration]
        )
        let context = container.mainContext

        // Full relationship graph: routine → block → log, goal ↔ session.
        let routine = Routine(name: "Teste", templateKey: "enem6m", startDate: .now)
        let block = RoutineBlock(weekday: 2, subject: "Matemática", targetMinutes: 50)
        block.routine = routine
        let log = RoutineLog(date: .now, subject: "Matemática", plannedMinutes: 50)
        log.block = block
        let goal = TopicGoal(subject: "Matemática", topic: "Funções", targetHours: 10)
        let session = FocusSession(plannedMinutes: 50, subject: "Matemática")
        session.goal = goal
        session.routine = routine

        context.insert(routine)
        context.insert(block)
        context.insert(log)
        context.insert(goal)
        context.insert(session)
        try context.save()

        let routines = try context.fetch(FetchDescriptor<Routine>())
        #expect(routines.count == 1)
        #expect(routines[0].blocks?.count == 1)
        #expect(routines[0].blocks?.first?.logs?.count == 1)
        #expect(routines[0].sessions?.count == 1)

        let goals = try context.fetch(FetchDescriptor<TopicGoal>())
        #expect(goals[0].sessions?.count == 1)
        #expect(goals[0].sessions?.first?.subject == "Matemática")

        let logs = try context.fetch(FetchDescriptor<RoutineLog>())
        #expect(logs[0].block?.routine === routines[0])
    }
}
