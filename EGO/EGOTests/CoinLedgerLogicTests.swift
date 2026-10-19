import Foundation
import Testing
@testable import EGO

@MainActor
struct CoinLedgerLogicTests {
    @Test func emptyLedgerBalancesToZero() {
        #expect(CoinLedgerLogic.balance(of: []) == 0)
    }

    @Test func balanceSumsCreditsAndDebits() {
        let transactions = [
            CoinTransaction(amount: 5, reason: CoinTransaction.Reason.sessionCompleted),
            CoinTransaction(amount: 30, reason: CoinTransaction.Reason.legacyBalance),
            CoinTransaction(amount: -10, reason: "shop.purchase"),
        ]
        #expect(CoinLedgerLogic.balance(of: transactions) == 25)
    }
}
