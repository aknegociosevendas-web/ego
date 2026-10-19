import Foundation
import Testing
@testable import EGO

@MainActor
struct StreakFreezeServiceTests {
    func makeContext() throws -> DIContainer {
        let container = try PersistenceController.makeInMemoryContainer()
        return DIContainer(modelContainer: container)
    }

    func credit(_ di: DIContainer, coins: Int) throws {
        let wallet = try di.walletRepository.fetchOrCreateWallet()
        wallet.coins = coins
        try di.walletRepository.append(CoinTransaction(
            amount: coins, reason: "test.credit", date: .now
        ))
    }

    @Test func purchaseDebitsWalletAndAddsFreeze() throws {
        let di = try makeContext()
        try credit(di, coins: 50)

        try di.streakFreezeService.buyFreeze()

        let wallet = try di.walletRepository.fetchOrCreateWallet()
        #expect(wallet.coins == 20)
        let streak = try di.streakRepository.fetchOrCreate()
        #expect(streak.freezesAvailable == 1)

        // Ledger integrity: debit recorded, balance still matches the wallet.
        let ledger = try di.walletRepository.allTransactions()
        #expect(ledger.contains {
            $0.reason == CoinTransaction.Reason.freezePurchase && $0.amount == -30
        })
        #expect(CoinLedgerLogic.balance(of: ledger) == wallet.coins)
    }

    @Test func purchaseFailsWithInsufficientCoins() throws {
        let di = try makeContext()
        try credit(di, coins: 10)

        #expect(throws: StreakFreezeService.PurchaseError.insufficientCoins) {
            try di.streakFreezeService.buyFreeze()
        }
        #expect(try di.walletRepository.fetchOrCreateWallet().coins == 10)
        #expect(try di.streakRepository.fetchOrCreate().freezesAvailable == 0)
    }

    @Test func purchaseFailsAtFreezeCap() throws {
        let di = try makeContext()
        try credit(di, coins: 100)
        let streak = try di.streakRepository.fetchOrCreate()
        streak.freezesAvailable = 2
        try di.streakRepository.save()

        #expect(throws: StreakFreezeService.PurchaseError.freezeCapReached) {
            try di.streakFreezeService.buyFreeze()
        }
        #expect(try di.walletRepository.fetchOrCreateWallet().coins == 100)
    }

    @Test func milestoneAwardsFreezeOnCompletion() throws {
        let di = try makeContext()
        // Streak at 2, qualified yesterday → today's session reaches milestone 3.
        let calendar = Calendar.current
        let streak = try di.streakRepository.fetchOrCreate()
        streak.current = 2
        streak.longest = 2
        streak.lastQualifiedDay = calendar.date(byAdding: .day, value: -1, to: .now)
        try di.streakRepository.save()

        let session = FocusSession(plannedMinutes: 25)
        session.actualMinutes = 25
        let result = try di.sessionCompletionService.completeSession(session)

        #expect(result.streakCurrent == 3)
        #expect(result.freezesEarned == 1)
        #expect(try di.streakRepository.fetchOrCreate().freezesAvailable == 1)
    }

    @Test func nonMilestoneDayAwardsNoFreeze() throws {
        let di = try makeContext()
        let calendar = Calendar.current
        let streak = try di.streakRepository.fetchOrCreate()
        streak.current = 3
        streak.longest = 3
        streak.lastQualifiedDay = calendar.date(byAdding: .day, value: -1, to: .now)
        try di.streakRepository.save()

        let session = FocusSession(plannedMinutes: 25)
        session.actualMinutes = 25
        let result = try di.sessionCompletionService.completeSession(session)

        #expect(result.streakCurrent == 4)
        #expect(result.freezesEarned == 0)
        #expect(try di.streakRepository.fetchOrCreate().freezesAvailable == 0)
    }
}
