import Foundation
import Testing
@testable import EGO

/// End-to-end: completing a session persists everything through the real
/// SwiftData repositories (in-memory container).
@MainActor
struct SessionCompletionServiceTests {
    func makeService() throws -> (SessionCompletionService, DIContainer) {
        let container = try PersistenceController.makeInMemoryContainer()
        let di = DIContainer(modelContainer: container)
        return (di.sessionCompletionService, di)
    }

    @Test func completedSessionAwardsEverything() throws {
        let (service, di) = try makeService()
        let session = FocusSession(plannedMinutes: 25, subject: "Matemática")
        session.actualMinutes = 25

        let result = try service.completeSession(session)

        #expect(result.xpEarned == 35)
        #expect(result.coinsEarned == 5)
        #expect(result.didLevelUp == false)
        #expect(result.newLevel == 1)
        #expect(result.streakOutcome == .started)
        #expect(result.streakCurrent == 1)

        let profile = try di.userProfileRepository.fetchOrCreate()
        #expect(profile.xp == 35)
        #expect(profile.level == 1)

        // Coins live in the wallet + ledger, not in the deprecated profile field.
        let wallet = try di.walletRepository.fetchOrCreateWallet()
        #expect(wallet.coins == 5)
        #expect(profile.coins == 0)
        let ledger = try di.walletRepository.allTransactions()
        #expect(ledger.count == 1)
        #expect(ledger[0].amount == 5)
        #expect(ledger[0].reason == CoinTransaction.Reason.sessionCompleted)
        #expect(ledger[0].date != nil)
        #expect(CoinLedgerLogic.balance(of: ledger) == wallet.coins)

        let stats = try di.userStatsRepository.fetchOrCreate()
        #expect(stats.totalSessions == 1)
        #expect(stats.totalFocusMinutes == 25)
        #expect(stats.currentStreak == 1)

        let subjectStats = try di.subjectStatRepository.fetchAll()
        #expect(subjectStats.count == 1)
        #expect(subjectStats[0].subject == "Matemática")
        #expect(subjectStats[0].focusMinutes == 25)

        #expect(di.mascotEvents.state == .happy)
    }

    @Test func secondSessionSameDayKeepsStreakAtOne() throws {
        let (service, di) = try makeService()

        let first = FocusSession(plannedMinutes: 25, subject: "Matemática")
        first.actualMinutes = 25
        try service.completeSession(first)

        let second = FocusSession(plannedMinutes: 50, subject: "Matemática")
        second.actualMinutes = 50
        let result = try service.completeSession(second)

        #expect(result.streakOutcome == .alreadyQualifiedToday)
        let stats = try di.userStatsRepository.fetchOrCreate()
        #expect(stats.currentStreak == 1)
        #expect(stats.totalSessions == 2)
        #expect(stats.totalFocusMinutes == 75)

        let profile = try di.userProfileRepository.fetchOrCreate()
        #expect(profile.xp == 35 + 60)

        let wallet = try di.walletRepository.fetchOrCreateWallet()
        #expect(wallet.coins == 10)
        #expect(try di.walletRepository.allTransactions().count == 2)

        // Same subject accumulates in one rollup, no duplicates.
        let subjectStats = try di.subjectStatRepository.fetchAll()
        #expect(subjectStats.count == 1)
        #expect(subjectStats[0].focusMinutes == 75)
    }

    @Test func sessionLargeEnoughTriggersLevelUp() throws {
        let (service, di) = try makeService()
        // 90 min + 10 bonus = 100 XP → exactly the level-2 threshold.
        let session = FocusSession(plannedMinutes: 90)
        session.actualMinutes = 90

        let result = try service.completeSession(session)

        #expect(result.didLevelUp)
        #expect(result.newLevel == 2)
        let profile = try di.userProfileRepository.fetchOrCreate()
        #expect(profile.level == 2)
        #expect(di.mascotEvents.state == .levelUp)
    }

    @Test func abandonedSessionEarnsNothingAndSaddensMascot() throws {
        let (service, di) = try makeService()
        let session = FocusSession(plannedMinutes: 25)
        session.actualMinutes = 10

        try service.abandonSession(session)

        let profile = try di.userProfileRepository.fetchOrCreate()
        #expect(profile.xp == 0)
        #expect(try di.walletRepository.fetchOrCreateWallet().coins == 0)

        let stats = try di.userStatsRepository.fetchOrCreate()
        #expect(stats.totalSessions == 0)
        #expect(stats.currentStreak == 0)

        // Recorded for history, flagged abandoned.
        let all = try di.focusRepository.fetchAll()
        #expect(all.count == 1)
        #expect(all[0].abandoned == true)
        #expect(all[0].completed == false)
        #expect(di.mascotEvents.state == .sad)
    }

    @Test func legacyProfileCoinsMigrateIntoWalletLedger() throws {
        let (service, di) = try makeService()
        // Simulate a pre-ledger install with coins on the profile.
        let profile = try di.userProfileRepository.fetchOrCreate()
        profile.coins = 30
        try di.userProfileRepository.save()

        let session = FocusSession(plannedMinutes: 25)
        session.actualMinutes = 25
        try service.completeSession(session)

        let wallet = try di.walletRepository.fetchOrCreateWallet()
        #expect(wallet.coins == 35) // 30 migrated + 5 earned

        let ledger = try di.walletRepository.allTransactions()
        #expect(ledger.count == 2)
        #expect(ledger.contains { $0.reason == CoinTransaction.Reason.legacyBalance && $0.amount == 30 })
        #expect(CoinLedgerLogic.balance(of: ledger) == wallet.coins)
    }

    @Test func sessionWithoutSubjectCreatesNoRollup() throws {
        let (service, di) = try makeService()
        let session = FocusSession(plannedMinutes: 25)
        session.actualMinutes = 25

        try service.completeSession(session)

        #expect(try di.subjectStatRepository.fetchAll().isEmpty)
    }
}
