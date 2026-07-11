import Foundation
import SwiftData

/// Weekly study routine (docs/03, F-05). One active routine at a time.
@Model
final class Routine {
    var id: UUID = UUID()
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now

    var name: String?
    var templateKey: String?
    var startDate: Date?
    var active: Bool = true

    @Relationship(inverse: \RoutineBlock.routine)
    var blocks: [RoutineBlock]?
    @Relationship(inverse: \FocusSession.routine)
    var sessions: [FocusSession]?

    init(name: String? = nil, templateKey: String? = nil, startDate: Date? = nil) {
        self.name = name
        self.templateKey = templateKey
        self.startDate = startDate
    }
}
