import Foundation

/// Ledger math: the wallet balance is always reconstructible from the
/// append-only `CoinTransaction` rows (survives CloudKit merge conflicts).
enum CoinLedgerLogic {
    static func balance(of transactions: [CoinTransaction]) -> Int {
        transactions.reduce(0) { $0 + $1.amount }
    }
}
