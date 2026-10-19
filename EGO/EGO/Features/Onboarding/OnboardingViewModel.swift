import Foundation
import Observation

/// F-17 flow state. This slice: welcome → notification opt-in. Remaining
/// steps (exam target, mascot naming, Screen Time) land in later phases.
@MainActor
@Observable
final class OnboardingViewModel {
    enum Step: Equatable {
        case welcome
        case notifications
    }

    private(set) var step: Step = .welcome
    private let notificationService: NotificationService

    init(notificationService: NotificationService) {
        self.notificationService = notificationService
    }

    func advanceToNotifications() {
        step = .notifications
    }

    /// Asks system permission; on grant, creates the default daily reminder
    /// and schedules everything.
    func enableNotifications() async {
        await notificationService.requestPermissionAndEnable()
    }
}
