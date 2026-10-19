import Foundation

/// Feeds topic goals from completed sessions (F-10). Attribution is by
/// subject match; explicit goal attach in the timer comes later.
@MainActor
final class GoalProgressService {
    struct Outcome: Equatable {
        var updatedGoals = 0
        var newlyCompletedGoals = 0
    }

    private let goalRepository: TopicGoalRepository

    init(goalRepository: TopicGoalRepository) {
        self.goalRepository = goalRepository
    }

    @discardableResult
    func recordSession(_ session: FocusSession, at date: Date = .now) throws -> Outcome {
        // Explicit attach (F-01) narrows attribution to that goal alone;
        // subject inheritance is the fallback for unattached sessions.
        if let goal = session.goal {
            guard !goal.completed else { return Outcome() }
            var outcome = Outcome()
            accumulate(session, into: goal, at: date, outcome: &outcome)
            try goalRepository.save()
            return outcome
        }

        guard let subject = session.subject, !subject.isEmpty else { return Outcome() }
        let goals = try goalRepository.activeGoals(subject: subject)
        guard !goals.isEmpty else { return Outcome() }

        var outcome = Outcome()
        for goal in goals {
            accumulate(session, into: goal, at: date, outcome: &outcome)
        }
        session.goal = goals.first
        try goalRepository.save()
        return outcome
    }

    /// Feeds question goals from a recorded attempt (F-10). Attributed by the
    /// question's subject to active goals — one increment per attempt, matching
    /// `UserStats.questionsSolved` (reviews count too, same as the stat).
    @discardableResult
    func recordQuestion(_ question: Question, at date: Date = .now) throws -> Outcome {
        guard let subject = question.subject, !subject.isEmpty else { return Outcome() }
        let goals = try goalRepository.activeGoals(subject: subject)
        guard !goals.isEmpty else { return Outcome() }

        var outcome = Outcome()
        for goal in goals {
            goal.progressQuestions += 1
            goal.updatedAt = date
            outcome.updatedGoals += 1
            if GoalLogic.isAchieved(goal) {
                goal.completed = true
                outcome.newlyCompletedGoals += 1
            }
        }
        try goalRepository.save()
        return outcome
    }

    /// Feeds essay goals from a finished draft (F-10). Essays aren't
    /// subject-scoped, so every active essay-target goal advances by one.
    @discardableResult
    func recordEssay(_ draft: EssayDraft, at date: Date = .now) throws -> Outcome {
        let goals = try goalRepository.activeEssayGoals()
        guard !goals.isEmpty else { return Outcome() }

        var outcome = Outcome()
        for goal in goals {
            goal.progressEssays += 1
            goal.updatedAt = date
            outcome.updatedGoals += 1
            if GoalLogic.isAchieved(goal) {
                goal.completed = true
                outcome.newlyCompletedGoals += 1
            }
        }
        try goalRepository.save()
        return outcome
    }

    private func accumulate(
        _ session: FocusSession,
        into goal: TopicGoal,
        at date: Date,
        outcome: inout Outcome
    ) {
        goal.progressMinutes += session.actualMinutes
        goal.updatedAt = date
        outcome.updatedGoals += 1
        if GoalLogic.isAchieved(goal) {
            goal.completed = true
            outcome.newlyCompletedGoals += 1
        }
    }
}
