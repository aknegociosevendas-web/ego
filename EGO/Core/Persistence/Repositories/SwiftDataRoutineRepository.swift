import Foundation
import SwiftData

@MainActor
final class SwiftDataRoutineRepository: RoutineRepository {
    private let context: ModelContext

    init(container: ModelContainer) {
        self.context = container.mainContext
    }

    func activeRoutine() throws -> Routine? {
        try context.fetch(FetchDescriptor<Routine>())
            .filter(\.active)
            .sorted { $0.createdAt > $1.createdAt }
            .first
    }

    func create(name: String?, templateKey: String?, startDate: Date) throws -> Routine {
        // Single active routine: retire any previous one.
        for routine in try context.fetch(FetchDescriptor<Routine>()) where routine.active {
            routine.active = false
            routine.updatedAt = .now
        }
        let routine = Routine(name: name, templateKey: templateKey, startDate: startDate)
        context.insert(routine)
        try context.save()
        return routine
    }

    @discardableResult
    func addBlock(
        to routine: Routine,
        weekday: Int,
        subject: String,
        targetMinutes: Int,
        targetSessions: Int,
        order: Int
    ) throws -> RoutineBlock {
        let block = RoutineBlock(
            weekday: weekday,
            subject: subject,
            targetMinutes: targetMinutes,
            targetSessions: targetSessions,
            order: order
        )
        block.routine = routine
        context.insert(block)
        routine.updatedAt = .now
        try context.save()
        return block
    }

    func updateBlock(
        _ block: RoutineBlock,
        weekday: Int,
        subject: String,
        targetMinutes: Int,
        targetSessions: Int
    ) throws {
        block.weekday = weekday
        block.subject = subject
        block.targetMinutes = targetMinutes
        block.targetSessions = targetSessions
        block.updatedAt = .now
        try context.save()
    }

    func deleteBlock(_ block: RoutineBlock) throws {
        context.delete(block)
        try context.save()
    }

    func save() throws {
        try context.save()
    }
}
