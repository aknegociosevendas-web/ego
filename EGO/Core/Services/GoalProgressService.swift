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
        guard let subject = session.subject, !subject.isEmpty else { return Outcome() }
        let goals = try goalRepository.activeGoals(subject: subject)
        guard !goals.isEmpty else { return Outcome() }

        var outcome = Outcome()
        for goal in goals {
            goal.progressMinutes += session.actualMinutes
            goal.updatedAt = date
            outcome.updatedGoals += 1
            if GoalLogic.isAchieved(goal) {
                goal.completed = true
                outcome.newlyCompletedGoals += 1
            }
        }
        session.goal = goals.first
        try goalRepository.save()
        return outcome
    }
}
