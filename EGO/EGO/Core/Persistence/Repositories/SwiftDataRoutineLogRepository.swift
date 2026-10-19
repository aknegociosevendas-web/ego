import Foundation
import SwiftData

@MainActor
final class SwiftDataRoutineLogRepository: RoutineLogRepository {
    private let context: ModelContext
    private let calendar: Calendar

    init(container: ModelContainer, calendar: Calendar = .current) {
        self.context = container.mainContext
        self.calendar = calendar
    }

    func log(for block: RoutineBlock, on day: Date) throws -> RoutineLog? {
        (block.logs ?? []).first { log in
            guard let date = log.date else { return false }
            return calendar.isDate(date, inSameDayAs: day)
        }
    }

    @discardableResult
    func createLog(for block: RoutineBlock, on day: Date) throws -> RoutineLog {
        let log = RoutineLog(
            date: calendar.startOfDay(for: day),
            subject: block.subject,
            plannedMinutes: block.targetMinutes
        )
        log.block = block
        context.insert(log)
        try context.save()
        return log
    }

    func logs(in interval: DateInterval) throws -> [RoutineLog] {
        try context.fetch(FetchDescriptor<RoutineLog>()).filter { log in
            guard let date = log.date else { return false }
            return interval.contains(date)
        }
    }

    func prune(olderThan date: Date) throws {
        let stale = try context.fetch(FetchDescriptor<RoutineLog>()).filter { log in
            guard let logDate = log.date else { return false }
            return logDate < date
        }
        guard !stale.isEmpty else { return }
        for log in stale {
            context.delete(log)
        }
        try context.save()
    }

    func save() throws {
        try context.save()
    }
}
