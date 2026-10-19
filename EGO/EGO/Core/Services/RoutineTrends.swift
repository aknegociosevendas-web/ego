import Foundation

/// Basic F-06 trends over the append-only log.
enum RoutineTrends {
    struct Consistency: Equatable {
        let plannedCount: Int
        let completedCount: Int

        var percentage: Double {
            guard plannedCount > 0 else { return 0 }
            return min(1, Double(completedCount) / Double(plannedCount))
        }
    }

    /// Completed vs planned block-days in the `days` window ending on
    /// `reference` (clamped to the routine's start).
    static func consistency(
        routine: Routine,
        logs: [RoutineLog],
        upTo reference: Date,
        days: Int = 28,
        calendar: Calendar
    ) -> Consistency {
        let end = calendar.startOfDay(for: reference)
        guard var cursor = calendar.date(byAdding: .day, value: -(days - 1), to: end) else {
            return Consistency(plannedCount: 0, completedCount: 0)
        }
        if let start = routine.startDate {
            cursor = max(cursor, calendar.startOfDay(for: start))
        }

        var planned = 0
        while cursor <= end {
            planned += RoutineLogic.blocks(of: routine, on: cursor, calendar: calendar).count
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }

        let completed = logs.filter { log in
            guard log.completed, let date = log.date else { return false }
            let day = calendar.startOfDay(for: date)
            return day <= end && calendar.dateComponents([.day], from: day, to: end).day ?? 0 < days
        }.count

        return Consistency(plannedCount: planned, completedCount: min(completed, planned))
    }

    /// Completed minutes per weekday (1 = Sunday … 7 = Saturday).
    static func minutesByWeekday(logs: [RoutineLog], calendar: Calendar) -> [Int: Int] {
        logs.reduce(into: [:]) { result, log in
            guard let date = log.date else { return }
            result[calendar.component(.weekday, from: date), default: 0] += log.completedMinutes
        }
    }
}
