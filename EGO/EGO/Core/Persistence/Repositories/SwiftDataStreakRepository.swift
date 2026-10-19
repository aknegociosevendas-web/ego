import Foundation
import SwiftData

@MainActor
final class SwiftDataStreakRepository: StreakRepository {
    private let context: ModelContext

    init(container: ModelContainer) {
        self.context = container.mainContext
    }

    func fetchOrCreate() throws -> Streak {
        if let existing = try context.fetch(FetchDescriptor<Streak>()).first {
            return existing
        }
        let streak = Streak()
        context.insert(streak)
        try context.save()
        return streak
    }

    func save() throws {
        try context.save()
    }
}
