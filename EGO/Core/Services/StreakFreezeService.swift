import Foundation

/// Buying streak freezes with coins (docs/07 §3–4). Earning via milestones
/// happens in `SessionCompletionService`.
@MainActor
final class StreakFreezeService {
    enum PurchaseError: Error, Equatable {
        case insufficientCoins
        case freezeCapReached
    }

    private let streakRepository: StreakRepository
    private let walletRepository: WalletRepository
    private let config: GamificationConfig

    var price: Int { config.freezePriceCoins }
    var maxFreezes: Int { config.maxFreezes }

    init(
        streakRepository: StreakRepository,
        walletRepository: WalletRepository,
        config: GamificationConfig = .standard
    ) {
        self.streakRepository = streakRepository
        self.walletRepository = walletRepository
        self.config = config
    }

    /// Debits the wallet (with a ledger entry) and adds one freeze.
    func buyFreeze(at date: Date = .now) throws {
        let streak = try streakRepository.fetchOrCreate()
        guard streak.freezesAvailable < config.maxFreezes else {
            throw PurchaseError.freezeCapReached
        }
        let wallet = try walletRepository.fetchOrCreateWallet()
        guard wallet.coins >= config.freezePriceCoins else {
            throw PurchaseError.insufficientCoins
        }

        wallet.coins -= config.freezePriceCoins
        wallet.updatedAt = date
        try walletRepository.append(CoinTransaction(
            amount: -config.freezePriceCoins,
            reason: CoinTransaction.Reason.freezePurchase,
            date: date
        ))
        streak.freezesAvailable += 1
        streak.updatedAt = date
        try streakRepository.save()
    }
}
