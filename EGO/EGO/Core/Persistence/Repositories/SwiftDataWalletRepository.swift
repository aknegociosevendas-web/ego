import Foundation
import SwiftData

@MainActor
final class SwiftDataWalletRepository: WalletRepository {
    private let context: ModelContext

    init(container: ModelContainer) {
        self.context = container.mainContext
    }

    func fetchOrCreateWallet() throws -> Wallet {
        if let existing = try context.fetch(FetchDescriptor<Wallet>()).first {
            return existing
        }
        let wallet = Wallet()
        // One-time migration: carry the deprecated UserProfile.coins balance
        // over as a ledger seed so history starts consistent.
        if let profile = try context.fetch(FetchDescriptor<UserProfile>()).first,
           profile.coins > 0 {
            wallet.coins = profile.coins
            context.insert(CoinTransaction(
                amount: profile.coins,
                reason: CoinTransaction.Reason.legacyBalance,
                date: .now
            ))
        }
        context.insert(wallet)
        try context.save()
        return wallet
    }

    func append(_ transaction: CoinTransaction) throws {
        context.insert(transaction)
        try context.save()
    }

    func allTransactions() throws -> [CoinTransaction] {
        try context.fetch(FetchDescriptor<CoinTransaction>(
            sortBy: [SortDescriptor(\.date)]
        ))
    }

    func save() throws {
        try context.save()
    }
}
