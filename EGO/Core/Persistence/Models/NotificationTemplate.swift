import Foundation
import SwiftData

/// Curated motivational phrase in the mascot's voice (docs/03, F-03).
/// Seeded from `NotificationPhraseCatalog` on first launch; stored as an
/// entity so the catalog can rotate/expand via sync later.
@Model
final class NotificationTemplate {
    /// Known `category` values.
    enum Category {
        static let reminder = "reminder"
        static let streak = "streak"
        static let comeback = "comeback"
        static let softFocus = "softFocus"
    }

    var id: UUID = UUID()
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now

    var key: String?
    var phrase: String?
    var category: String?

    init(key: String? = nil, phrase: String? = nil, category: String? = nil) {
        self.key = key
        self.phrase = phrase
        self.category = category
    }
}
