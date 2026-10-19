import Foundation

/// Pure aggregation of focus sessions into chart-ready buckets (F-11).
enum StatsAggregator {
    struct DailyMinutes: Equatable, Identifiable {
        let day: Date
        let minutes: Int
        var id: Date { day }
    }

    /// One bucket per day (zeros included) for the `days` days ending on
    /// `reference`'s day, oldest first. Only completed sessions count.
    static func dailyMinutes(
        from sessions: [FocusSession],
        endingOn reference: Date,
        days: Int = 7,
        calendar: Calendar
    ) -> [DailyMinutes] {
        let lastDay = calendar.startOfDay(for: reference)
        return stride(from: -(days - 1), through: 0, by: 1).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: lastDay) else {
                return nil
            }
            let minutes = sessions
                .filter { session in
                    guard session.completed, let endedAt = session.endedAt else { return false }
                    return calendar.isDate(endedAt, inSameDayAs: day)
                }
                .reduce(0) { $0 + $1.actualMinutes }
            return DailyMinutes(day: day, minutes: minutes)
        }
    }
}
