import Foundation

/// Persistence boundary for motivational phrase templates (F-03).
@MainActor
protocol NotificationTemplateRepository: AnyObject {
    /// Phrases of a category, key-sorted for deterministic rotation.
    func phrases(category: String) throws -> [String]
    /// Full templates of a category (weighted selection, slice 7).
    func templates(category: String) throws -> [NotificationTemplate]
    /// Template by catalog key (deep-link resolution).
    func template(key: String) throws -> NotificationTemplate?
    /// Creates or updates a catalog row; preserves `lastUsedAt` on update.
    func upsert(key: String, phrase: String, category: String, weight: Double) throws
    /// Persists pending mutations (e.g. `lastUsedAt` stamps).
    func save() throws
    /// Inserts the bundled catalog on first launch.
    func seedIfNeeded() throws
}
