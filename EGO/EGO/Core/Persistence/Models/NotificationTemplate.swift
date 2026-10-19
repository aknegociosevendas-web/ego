import Foundation
import SwiftData

/// Curated motivational phrase in the mascot's voice (docs/03, F-03).
/// Seeded from the bundled `motivational-phrases.json` (slice 7) plus the
/// legacy `NotificationPhraseCatalog` softFocus entries; stored as an entity
/// so the catalog can rotate/expand via sync later. `key` holds the catalog
/// id (e.g. "cb-001") and `phrase` the text — CloudKit-safe: everything
/// optional/defaulted, standalone (no relationships).
@Model
final class NotificationTemplate {
    /// Legacy `category` values (pre-slice-7 seeds); new rows use
    /// `NotificationCategory` raw values.
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
    /// Weighted-random selection weight (promoted phrases carry 1.5).
    var weight: Double = 1.0
    /// Set by the selector so recent phrases aren't repeated within 14 days.
    var lastUsedAt: Date?

    init(
        key: String? = nil,
        phrase: String? = nil,
        category: String? = nil,
        weight: Double = 1.0,
        lastUsedAt: Date? = nil
    ) {
        self.key = key
        self.phrase = phrase
        self.category = category
        self.weight = weight
        self.lastUsedAt = lastUsedAt
    }
}
