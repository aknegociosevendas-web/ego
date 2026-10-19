import Foundation
import SwiftData

/// Canonical coin balance (docs/03, docs/07 §3). Denormalized cache of the
/// append-only `CoinTransaction` ledger — always rebuildable by summing it.
/// Supersedes the deprecated `UserProfile.coins` (kept in the schema for
/// CloudKit compatibility, no longer written).
@Model
final class Wallet {
    var id: UUID = UUID()
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now

    var coins: Int = 0

    init() {}
}
