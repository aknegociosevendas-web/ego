import Foundation

/// Finalizing an essay draft (F-08): rubric self-score, stats, XP, mascot.
@MainActor
final class EssayService {
    private let essayRepository: EssayRepository
    private let userStatsRepository: UserStatsRepository
    private let goalProgressService: GoalProgressService
    private let xpService: XPService
    private let mascotEvents: MascotEventCenter
    private let config: GamificationConfig

    init(
        essayRepository: EssayRepository,
        userStatsRepository: UserStatsRepository,
        goalProgressService: GoalProgressService,
        xpService: XPService,
        mascotEvents: MascotEventCenter,
        config: GamificationConfig = .standard
    ) {
        self.essayRepository = essayRepository
        self.userStatsRepository = userStatsRepository
        self.goalProgressService = goalProgressService
        self.xpService = xpService
        self.mascotEvents = mascotEvents
        self.config = config
    }

    static func wordCount(of text: String) -> Int {
        text.split { $0.isWhitespace || $0.isNewline }.count
    }

    /// Returns the rubric total (0–1000 for ENEM).
    @discardableResult
    func finalize(
        _ draft: EssayDraft,
        competencyScores: [Int],
        at date: Date = .now
    ) throws -> Int {
        let total = competencyScores.reduce(0, +)
        draft.competencyScores = competencyScores
        draft.selfScore = total
        draft.finishedAt = date
        draft.wordCount = Self.wordCount(of: draft.bodyText ?? "")
        draft.updatedAt = date

        let stats = try userStatsRepository.fetchOrCreate()
        stats.essaysFinished += 1
        stats.lastActiveDay = date
        stats.updatedAt = date

        try essayRepository.save()

        // A finished essay feeds every active essay-target goal (F-10).
        let goalOutcome = (try? goalProgressService.recordEssay(draft, at: date)) ?? .init()

        let xp = config.xpPerEssayFinished
            + goalOutcome.newlyCompletedGoals * config.xpPerGoalCompleted
        let didLevelUp = try xpService.grant(xp, at: date)
        if !didLevelUp {
            if goalOutcome.newlyCompletedGoals > 0 {
                mascotEvents.goalCompleted()
            } else {
                mascotEvents.essayFinished()
            }
        }
        return total
    }
}
