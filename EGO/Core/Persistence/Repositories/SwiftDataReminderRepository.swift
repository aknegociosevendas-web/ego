import Foundation
import SwiftData

@MainActor
final class SwiftDataReminderRepository: ReminderRepository {
    private let context: ModelContext
    private let calendar: Calendar

    init(container: ModelContainer, calendar: Calendar = .current) {
        self.context = container.mainContext
        self.calendar = calendar
    }

    func sessionReminder() throws -> Reminder? {
        try context.fetch(FetchDescriptor<Reminder>())
            .first { $0.type == Reminder.Kind.session }
    }

    func createSessionReminder(hour: Int, minute: Int) throws -> Reminder {
        if let existing = try sessionReminder() {
            return existing
        }
        let time = calendar.date(
            bySettingHour: hour, minute: minute, second: 0, of: .now
        )
        let reminder = Reminder(time: time, type: Reminder.Kind.session)
        context.insert(reminder)
        try context.save()
        return reminder
    }

    func save() throws {
        try context.save()
    }
}
