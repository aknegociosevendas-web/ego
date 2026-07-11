import Foundation
import SwiftData

/// Append-only coin ledger entry (docs/03, docs/07 §3). Standalone rows with
/// no relationships: independent records merge cleanly under CloudKit sync,
/// and the wallet balance can always be reconciled by summing them.
@Model
final class CoinTransaction {
    /// Known `reason` values.
    enum Reason {
        static let sessionCompleted = "session.completed"
        static let freezePurchase = "freeze.purchase"
        /// One-time seed migrating the deprecated `UserProfile.coins` balance.
        static let legacyBalance = "legacy.balance"
    }

    var id: UUID = UUID()
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now

    var amount: Int = 0
    var reason: String?
    var date: Date?

    init(amount: Int, reason: String? = nil, date: Date? = nil) {
        self.amount = amount
        self.reason = reason
        self.date = date
    }
}
