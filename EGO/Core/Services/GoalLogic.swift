import Foundation

/// Pure goal math (F-10). Hours, question, and essay targets all feed goal
/// progress and completion.
enum GoalLogic {
    static func targetMinutes(of goal: TopicGoal) -> Int? {
        goal.targetHours.map { Int(($0 * 60).rounded()) }
    }

    /// A goal is achieved when *all* of its defined targets are met. Goals
    /// without any target never auto-complete.
    static func isAchieved(_ goal: TopicGoal) -> Bool {
        var hasTarget = false
        if let target = targetMinutes(of: goal), target > 0 {
            hasTarget = true
            if goal.progressMinutes < target { return false }
        }
        if let target = goal.targetQuestions, target > 0 {
            hasTarget = true
            if goal.progressQuestions < target { return false }
        }
        if let target = goal.targetEssays, target > 0 {
            hasTarget = true
            if goal.progressEssays < target { return false }
        }
        return hasTarget
    }

    /// 0…1 progress toward the hours target.
    static func hoursProgress(_ goal: TopicGoal) -> Double {
        guard let target = targetMinutes(of: goal), target > 0 else { return 0 }
        return min(1, Double(goal.progressMinutes) / Double(target))
    }

    /// 0…1 progress toward the questions target.
    static func questionsProgress(_ goal: TopicGoal) -> Double {
        guard let target = goal.targetQuestions, target > 0 else { return 0 }
        return min(1, Double(goal.progressQuestions) / Double(target))
    }

    /// 0…1 progress toward the essays target.
    static func essaysProgress(_ goal: TopicGoal) -> Double {
        guard let target = goal.targetEssays, target > 0 else { return 0 }
        return min(1, Double(goal.progressEssays) / Double(target))
    }
}
