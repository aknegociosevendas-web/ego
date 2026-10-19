import Foundation

/// Persistence boundary for the coin wallet + append-only ledger.
@MainActor
protocol WalletRepository: AnyObject {
    /// Returns the wallet, creating it on first access (migrating any legacy
    /// `UserProfile.coins` balance into the ledger).
    func fetchOrCreateWallet() throws -> Wallet
    func append(_ transaction: CoinTransaction) throws
    func allTransactions() throws -> [CoinTransaction]
    func save() throws
}
