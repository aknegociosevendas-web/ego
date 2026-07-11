import Foundation
import SwiftData

@MainActor
final class SwiftDataTopicGoalRepository: TopicGoalRepository {
    private let context: ModelContext

    init(container: ModelContainer) {
        self.context = container.mainContext
    }

    func fetchAll() throws -> [TopicGoal] {
        try context.fetch(FetchDescriptor<TopicGoal>())
            .sorted { $0.createdAt > $1.createdAt }
    }

    func activeGoals(subject: String) throws -> [TopicGoal] {
        try fetchAll().filter { !$0.completed && $0.subject == subject }
    }

    @discardableResult
    func create(
        subject: String,
        topic: String?,
        targetHours: Double?,
        targetQuestions: Int?,
        deadline: Date?
    ) throws -> TopicGoal {
        let goal = TopicGoal(
            subject: subject,
            topic: topic,
            targetHours: targetHours,
            targetQuestions: targetQuestions,
            deadline: deadline
        )
        context.insert(goal)
        try context.save()
        return goal
    }

    func delete(_ goal: TopicGoal) throws {
        context.delete(goal)
        try context.save()
    }

    func save() throws {
        try context.save()
    }
}
