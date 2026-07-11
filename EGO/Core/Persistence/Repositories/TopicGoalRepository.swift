import Foundation

/// Persistence boundary for topic goals (F-10).
@MainActor
protocol TopicGoalRepository: AnyObject {
    func fetchAll() throws -> [TopicGoal]
    /// Incomplete goals for a subject (session progress attribution).
    func activeGoals(subject: String) throws -> [TopicGoal]
    @discardableResult
    func create(
        subject: String,
        topic: String?,
        targetHours: Double?,
        targetQuestions: Int?,
        deadline: Date?
    ) throws -> TopicGoal
    func delete(_ goal: TopicGoal) throws
    func save() throws
}
