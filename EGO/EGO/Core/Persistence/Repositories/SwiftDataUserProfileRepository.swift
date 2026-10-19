import Foundation
import SwiftData

@MainActor
final class SwiftDataUserProfileRepository: UserProfileRepository {
    private let context: ModelContext

    init(container: ModelContainer) {
        self.context = container.mainContext
    }

    func fetchOrCreate() throws -> UserProfile {
        if let existing = try context.fetch(FetchDescriptor<UserProfile>()).first {
            return existing
        }
        let profile = UserProfile()
        context.insert(profile)
        try context.save()
        return profile
    }

    func save() throws {
        try context.save()
    }
}
