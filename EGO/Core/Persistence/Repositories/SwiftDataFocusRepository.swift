import Foundation
import SwiftData

/// SwiftData-backed repository operating on the container's main context.
@MainActor
final class SwiftDataFocusRepository: FocusRepository {
    private let context: ModelContext

    init(container: ModelContainer) {
        self.context = container.mainContext
    }

    func save(_ session: FocusSession) throws {
        context.insert(session)
        try context.save()
    }

    func fetchAll() throws -> [FocusSession] {
        let descriptor = FetchDescriptor<FocusSession>(
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func fetch(id: UUID) throws -> FocusSession? {
        var descriptor = FetchDescriptor<FocusSession>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    func completedSessions(in interval: DateInterval) throws -> [FocusSession] {
        // Session volume is small; filter the optional date in memory rather
        // than fighting #Predicate optional-unwrapping.
        let descriptor = FetchDescriptor<FocusSession>(
            predicate: #Predicate { $0.completed == true }
        )
        return try context.fetch(descriptor).filter { session in
            guard let endedAt = session.endedAt else { return false }
            return interval.contains(endedAt)
        }
    }

    func delete(_ session: FocusSession) throws {
        context.delete(session)
        try context.save()
    }
}
