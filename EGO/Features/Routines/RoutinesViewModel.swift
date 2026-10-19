import Foundation
import Observation

/// F-05/F-06 state: active routine, today's agenda, weekly editor, trends.
@MainActor
@Observable
final class RoutinesViewModel {
    struct TodayEntry: Identifiable, Equatable {
        let blockID: UUID
        let subject: String
        let targetMinutes: Int
        let completedMinutes: Int
        let completed: Bool
        var id: UUID { blockID }
    }

    private let routineRepository: RoutineRepository
    private let routineLogRepository: RoutineLogRepository
    private let routineProgressService: RoutineProgressService
    private let subjectStatRepository: SubjectStatRepository
    private let reviewItemRepository: ReviewItemRepository
    private let calendar: Calendar

    private(set) var routine: Routine?
    private(set) var todayEntries: [TodayEntry] = []
    private(set) var consistency: RoutineTrends.Consistency?
    private(set) var suggestion: SuggestionLogic.Suggestion?
    private(set) var dueReviewCount = 0

    init(
        routineRepository: RoutineRepository,
        routineLogRepository: RoutineLogRepository,
        routineProgressService: RoutineProgressService,
        subjectStatRepository: SubjectStatRepository,
        reviewItemRepository: ReviewItemRepository,
        calendar: Calendar = .current
    ) {
        self.routineRepository = routineRepository
        self.routineLogRepository = routineLogRepository
        self.routineProgressService = routineProgressService
        self.subjectStatRepository = subjectStatRepository
        self.reviewItemRepository = reviewItemRepository
        self.calendar = calendar
    }

    /// Blocks grouped for the weekly editor, weekdays with content only.
    var weekdaysWithBlocks: [(weekday: Int, blocks: [RoutineBlock])] {
        guard let routine else { return [] }
        let grouped = Dictionary(grouping: routine.blocks ?? []) { $0.weekday ?? 0 }
        return grouped.keys.sorted().map { weekday in
            (weekday, grouped[weekday]!.sorted { $0.order < $1.order })
        }
    }

    func refresh(now: Date = .now) {
        // Performance signals (F-07 → suggestions) don't depend on a routine.
        suggestion = SuggestionLogic.weakestSubject(
            from: (try? subjectStatRepository.fetchAll()) ?? []
        )
        dueReviewCount = (try? reviewItemRepository.dueItems(on: now).count) ?? 0

        routine = try? routineRepository.activeRoutine()
        guard let routine else {
            todayEntries = []
            consistency = nil
            return
        }

        todayEntries = RoutineLogic.blocks(of: routine, on: now, calendar: calendar).map { block in
            let log = try? routineLogRepository.log(for: block, on: now)
            return TodayEntry(
                blockID: block.id,
                subject: block.subject ?? "",
                targetMinutes: block.targetMinutes,
                completedMinutes: log?.completedMinutes ?? 0,
                completed: log?.completed ?? false
            )
        }

        let windowStart = calendar.date(byAdding: .day, value: -27, to: calendar.startOfDay(for: now)) ?? now
        let logs = (try? routineLogRepository.logs(
            in: DateInterval(start: windowStart, end: now)
        )) ?? []
        consistency = RoutineTrends.consistency(
            routine: routine, logs: logs, upTo: now, calendar: calendar
        )
    }

    func createRoutine(fromTemplateKey key: String) {
        guard let template = RoutineTemplateCatalog.template(forKey: key) else { return }
        guard let routine = try? routineRepository.create(
            name: template.name, templateKey: template.key, startDate: .now
        ) else { return }
        for (index, spec) in template.blocks.enumerated() {
            _ = try? routineRepository.addBlock(
                to: routine,
                weekday: spec.weekday,
                subject: spec.subject,
                targetMinutes: spec.minutes,
                targetSessions: spec.sessions,
                order: index
            )
        }
        refresh()
    }

    func createEmptyRoutine() {
        _ = try? routineRepository.create(name: nil, templateKey: nil, startDate: .now)
        refresh()
    }

    func addBlock(weekday: Int, subject: String, minutes: Int, sessions: Int) {
        guard let routine else { return }
        let order = (routine.blocks ?? []).count
        _ = try? routineRepository.addBlock(
            to: routine,
            weekday: weekday,
            subject: subject,
            targetMinutes: minutes,
            targetSessions: sessions,
            order: order
        )
        refresh()
    }

    /// In-place edit: identity and log history preserved; today's log
    /// resyncs to the new target.
    func updateBlock(_ block: RoutineBlock, weekday: Int, subject: String, minutes: Int, sessions: Int) {
        try? routineRepository.updateBlock(
            block,
            weekday: weekday,
            subject: subject,
            targetMinutes: minutes,
            targetSessions: sessions
        )
        try? routineProgressService.syncTodayLog(for: block)
        refresh()
    }

    func deleteBlock(_ block: RoutineBlock) {
        try? routineRepository.deleteBlock(block)
        refresh()
    }

    func checkOff(_ entry: TodayEntry) {
        guard let block = (routine?.blocks ?? []).first(where: { $0.id == entry.blockID }) else {
            return
        }
        _ = try? routineProgressService.checkOff(block)
        refresh()
    }
}
