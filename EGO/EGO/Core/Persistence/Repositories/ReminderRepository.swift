import Foundation

/// Persistence boundary for reminders (F-09).
@MainActor
protocol ReminderRepository: AnyObject {
    /// The single daily session reminder, if the user opted in.
    func sessionReminder() throws -> Reminder?
    func createSessionReminder(hour: Int, minute: Int) throws -> Reminder
    func save() throws
}
