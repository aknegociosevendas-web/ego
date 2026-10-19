import Foundation
import SwiftData

@MainActor
final class SwiftDataSubjectStatRepository: SubjectStatRepository {
    private let context: ModelContext

    init(container: ModelContainer) {
        self.context = container.mainContext
    }

    func fetchAll() throws -> [SubjectStat] {
        try context.fetch(FetchDescriptor<SubjectStat>())
    }

    func fetchOrCreate(subject: String, attachedTo stats: UserStats?) throws -> SubjectStat {
        if let existing = try fetchAll().first(where: { $0.subject == subject }) {
            return existing
        }
        let stat = SubjectStat(subject: subject)
        stat.stats = stats
        context.insert(stat)
        try context.save()
        return stat
    }

    func save() throws {
        try context.save()
    }
}
