import Foundation

/// Array-backed repository for previews and tests — no persistence, no SwiftData.
@MainActor
final class InMemoryFocusRepository: FocusRepository {
    private var sessions: [FocusSession] = []

    func save(_ session: FocusSession) throws {
        guard !sessions.contains(where: { $0.id == session.id }) else { return }
        sessions.append(session)
    }

    func fetchAll() throws -> [FocusSession] {
        sessions
    }

    func fetch(id: UUID) throws -> FocusSession? {
        sessions.first { $0.id == id }
    }

    func completedSessions(in interval: DateInterval) throws -> [FocusSession] {
        sessions.filter { session in
            guard session.completed, let endedAt = session.endedAt else { return false }
            return interval.contains(endedAt)
        }
    }

    func delete(_ session: FocusSession) throws {
        sessions.removeAll { $0.id == session.id }
    }
}
