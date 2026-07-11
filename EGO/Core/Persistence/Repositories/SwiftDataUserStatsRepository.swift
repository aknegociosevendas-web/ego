import Foundation
import SwiftData

@MainActor
final class SwiftDataUserStatsRepository: UserStatsRepository {
    private let context: ModelContext

    init(container: ModelContainer) {
        self.context = container.mainContext
    }

    func fetchOrCreate() throws -> UserStats {
        if let existing = try context.fetch(FetchDescriptor<UserStats>()).first {
            return existing
        }
        let stats = UserStats()
        context.insert(stats)
        try context.save()
        return stats
    }

    func save() throws {
        try context.save()
    }
}
