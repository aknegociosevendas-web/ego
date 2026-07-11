import Foundation

/// Pure goal math (F-10). Question/essay targets join in Phase 3.
enum GoalLogic {
    static func targetMinutes(of goal: TopicGoal) -> Int? {
        goal.targetHours.map { Int(($0 * 60).rounded()) }
    }

    /// A goal is achieved when its hours target is met (only supported
    /// target so far). Goals without targets never auto-complete.
    static func isAchieved(_ goal: TopicGoal) -> Bool {
        guard let target = targetMinutes(of: goal), target > 0 else { return false }
        return goal.progressMinutes >= target
    }

    /// 0…1 progress toward the hours target.
    static func hoursProgress(_ goal: TopicGoal) -> Double {
        guard let target = targetMinutes(of: goal), target > 0 else { return 0 }
        return min(1, Double(goal.progressMinutes) / Double(target))
    }
}
