import Foundation
import SwiftData

@MainActor
final class SwiftDataNotificationTemplateRepository: NotificationTemplateRepository {
    private let context: ModelContext

    init(container: ModelContainer) {
        self.context = container.mainContext
    }

    func phrases(category: String) throws -> [String] {
        try context.fetch(FetchDescriptor<NotificationTemplate>())
            .filter { $0.category == category }
            .sorted { ($0.key ?? "") < ($1.key ?? "") }
            .compactMap(\.phrase)
    }

    func seedIfNeeded() throws {
        // Upsert by key so catalog additions reach existing installs.
        let existingKeys = Set(
            try context.fetch(FetchDescriptor<NotificationTemplate>()).compactMap(\.key)
        )
        let missing = NotificationPhraseCatalog.seeds.filter { !existingKeys.contains($0.key) }
        guard !missing.isEmpty else { return }
        for entry in missing {
            context.insert(NotificationTemplate(
                key: entry.key,
                phrase: entry.phrase,
                category: entry.category
            ))
        }
        try context.save()
    }
}
