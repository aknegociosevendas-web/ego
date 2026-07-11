import Foundation

/// Pure routine queries (F-05): which blocks apply today, which block a
/// completed session feeds.
enum RoutineLogic {
    /// Blocks scheduled for `date`'s weekday, in editor order.
    static func blocks(of routine: Routine, on date: Date, calendar: Calendar) -> [RoutineBlock] {
        let weekday = calendar.component(.weekday, from: date)
        return (routine.blocks ?? [])
            .filter { $0.weekday == weekday }
            .sorted { $0.order < $1.order }
    }

    /// First of today's blocks matching the session's subject.
    static func matchingBlock(
        in routine: Routine,
        subject: String?,
        on date: Date,
        calendar: Calendar
    ) -> RoutineBlock? {
        guard let subject, !subject.isEmpty else { return nil }
        return blocks(of: routine, on: date, calendar: calendar)
            .first { $0.subject == subject }
    }
}
