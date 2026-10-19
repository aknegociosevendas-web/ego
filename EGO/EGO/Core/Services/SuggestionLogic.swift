import Foundation

/// Performance → goal/routine suggestions (docs/08 §1): surfaces the weakest
/// subject once there is enough signal.
enum SuggestionLogic {
    struct Suggestion: Equatable {
        let subject: String
        /// 0…1 accuracy.
        let accuracy: Double
    }

    /// Weakest subject with at least `minimumAttempts` answers and accuracy
    /// below `threshold`; nil when there's nothing actionable.
    static func weakestSubject(
        from stats: [SubjectStat],
        minimumAttempts: Int = 10,
        threshold: Double = 0.75
    ) -> Suggestion? {
        stats
            .compactMap { stat -> Suggestion? in
                guard
                    let subject = stat.subject, !subject.isEmpty,
                    stat.questionsSolved >= minimumAttempts
                else { return nil }
                let accuracy = Double(stat.questionsCorrect) / Double(stat.questionsSolved)
                guard accuracy < threshold else { return nil }
                return Suggestion(subject: subject, accuracy: accuracy)
            }
            .min { $0.accuracy < $1.accuracy }
    }
}
