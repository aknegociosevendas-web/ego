import Foundation
import Observation

/// F-10 state: goal list with progress, creation and removal.
@MainActor
@Observable
final class GoalsViewModel {
    struct GoalRow: Identifiable, Equatable {
        let id: UUID
        let subject: String
        let topic: String?
        let progressMinutes: Int
        let targetMinutes: Int?
        let progress: Double
        let deadline: Date?
        let overdue: Bool
        let completed: Bool
    }

    private let goalRepository: TopicGoalRepository
    private let calendar: Calendar

    private(set) var rows: [GoalRow] = []

    init(goalRepository: TopicGoalRepository, calendar: Calendar = .current) {
        self.goalRepository = goalRepository
        self.calendar = calendar
    }

    func refresh(now: Date = .now) {
        let goals = (try? goalRepository.fetchAll()) ?? []
        rows = goals.map { goal in
            let overdue = !goal.completed && (goal.deadline.map { $0 < calendar.startOfDay(for: now) } ?? false)
            return GoalRow(
                id: goal.id,
                subject: goal.subject ?? "",
                topic: goal.topic?.isEmpty == false ? goal.topic : nil,
                progressMinutes: goal.progressMinutes,
                targetMinutes: GoalLogic.targetMinutes(of: goal),
                progress: GoalLogic.hoursProgress(goal),
                deadline: goal.deadline,
                overdue: overdue,
                completed: goal.completed
            )
        }
    }

    func createGoal(subject: String, topic: String, targetHours: Double, deadline: Date?) {
        _ = try? goalRepository.create(
            subject: subject,
            topic: topic.isEmpty ? nil : topic,
            targetHours: targetHours,
            targetQuestions: nil,
            deadline: deadline
        )
        refresh()
    }

    func deleteGoal(_ row: GoalRow) {
        guard let goal = (try? goalRepository.fetchAll())?.first(where: { $0.id == row.id }) else {
            return
        }
        try? goalRepository.delete(goal)
        refresh()
    }
}
