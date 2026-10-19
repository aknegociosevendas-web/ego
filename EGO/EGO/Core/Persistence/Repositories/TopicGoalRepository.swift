import Foundation

/// Persistence boundary for topic goals (F-10).
@MainActor
protocol TopicGoalRepository: AnyObject {
    func fetchAll() throws -> [TopicGoal]
    func fetch(id: UUID) throws -> TopicGoal?
    /// Incomplete goals for a subject (session progress attribution).
    func activeGoals(subject: String) throws -> [TopicGoal]
    /// Incomplete goals with an essay target (essays aren't subject-scoped,
    /// so a finished essay feeds all of these).
    func activeEssayGoals() throws -> [TopicGoal]
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
