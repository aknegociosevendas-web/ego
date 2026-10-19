import Foundation
import SwiftData

/// User-configurable reminder (docs/03, F-09). This slice ships a single
/// daily "session" reminder created on notification opt-in; editing UI and
/// per-subject/routine reminders land with Settings (F-18).
@Model
final class Reminder {
    /// Known `type` values.
    enum Kind {
        static let session = "session"
    }

    var id: UUID = UUID()
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now

    var title: String?
    var body: String?
    /// Only the hour/minute components are meaningful for daily reminders.
    var time: Date?
    var weekdays: [Int]?
    var subject: String?
    var type: String?
    var enabled: Bool = true

    init(time: Date? = nil, type: String? = nil) {
        self.time = time
        self.type = type
    }
}
