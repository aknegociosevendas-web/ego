import Foundation

/// Persistence boundary for motivational phrase templates (F-03).
@MainActor
protocol NotificationTemplateRepository: AnyObject {
    /// Phrases of a category, key-sorted for deterministic rotation.
    func phrases(category: String) throws -> [String]
    /// Inserts the bundled catalog on first launch.
    func seedIfNeeded() throws
}
