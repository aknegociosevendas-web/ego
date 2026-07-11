import Foundation

/// Orchestrates F-03/F-09: reads state from repositories, plans via
/// `NotificationPlanner`, applies via the scheduler. Re-planning always
/// replaces pending requests (fixed identifiers).
@MainActor
final class NotificationService {
    private let scheduler: NotificationScheduling
    private let reminderRepository: ReminderRepository
    private let templateRepository: NotificationTemplateRepository
    private let streakRepository: StreakRepository
    private let userStatsRepository: UserStatsRepository
    private let userProfileRepository: UserProfileRepository
    private let config: NotificationConfig
    private let gamification: GamificationConfig
    private let calendar: Calendar

    init(
        scheduler: NotificationScheduling,
        reminderRepository: ReminderRepository,
        templateRepository: NotificationTemplateRepository,
        streakRepository: StreakRepository,
        userStatsRepository: UserStatsRepository,
        userProfileRepository: UserProfileRepository,
        config: NotificationConfig = .standard,
        gamification: GamificationConfig = .standard,
        calendar: Calendar = .current
    ) {
        self.scheduler = scheduler
        self.reminderRepository = reminderRepository
        self.templateRepository = templateRepository
        self.streakRepository = streakRepository
        self.userStatsRepository = userStatsRepository
        self.userProfileRepository = userProfileRepository
        self.config = config
        self.gamification = gamification
        self.calendar = calendar
    }

    /// Onboarding opt-in: ask permission, create the default daily reminder,
    /// schedule everything. Returns whether permission was granted.
    @discardableResult
    func requestPermissionAndEnable() async -> Bool {
        let granted = await scheduler.requestAuthorization()
        guard granted else { return false }
        _ = try? reminderRepository.createSessionReminder(
            hour: config.defaultReminderHour, minute: 0
        )
        await refreshSchedules()
        return true
    }

    /// Re-plans all three triggers from current state. Called on scene
    /// background and after session completion.
    func refreshSchedules(now: Date = .now) async {
        guard await scheduler.isAuthorized() else { return }
        try? templateRepository.seedIfNeeded()
        let title = notificationTitle()

        // 1. Daily session reminder.
        scheduler.cancel(identifiers: [NotificationConfig.Identifier.sessionReminder])
        if let reminder = try? reminderRepository.sessionReminder(),
           reminder.enabled,
           let time = reminder.time {
            let components = calendar.dateComponents([.hour, .minute], from: time)
            await scheduler.schedule(NotificationPlanner.sessionReminder(
                hour: components.hour ?? config.defaultReminderHour,
                minute: components.minute ?? 0,
                title: title,
                body: phrase(NotificationTemplate.Category.reminder, on: now),
                config: config
            ))
        }

        // 2. Streak at risk (today, one-shot).
        scheduler.cancel(identifiers: [NotificationConfig.Identifier.streakRisk])
        if let streak = try? streakRepository.fetchOrCreate(),
           let planned = NotificationPlanner.streakRisk(
               streakCurrent: streak.current,
               lastQualifiedDay: streak.lastQualifiedDay,
               now: now,
               calendar: calendar,
               riskHour: gamification.streakRiskHour,
               title: title,
               body: phrase(NotificationTemplate.Category.streak, on: now)
           ) {
            await scheduler.schedule(planned)
        }

        // 3. Comeback nudge.
        scheduler.cancel(identifiers: [NotificationConfig.Identifier.comeback])
        if let stats = try? userStatsRepository.fetchOrCreate(),
           let planned = NotificationPlanner.comeback(
               lastActiveDay: stats.lastActiveDay,
               now: now,
               calendar: calendar,
               title: title,
               body: phrase(NotificationTemplate.Category.comeback, on: now),
               config: config
           ) {
            await scheduler.schedule(planned)
        }
    }

    /// Today qualified: the risk nudge is moot. Everything else (comeback
    /// window, tomorrow's risk) is re-planned on scene background — which
    /// always precedes any pending notification actually firing.
    func sessionDidComplete() {
        scheduler.cancel(identifiers: [NotificationConfig.Identifier.streakRisk])
    }

    /// Soft-focus (docs/06 §7): nudge fired right after the user leaves the
    /// app mid-session; cancelled if they come back. Repository access stays
    /// synchronous here — the detached task must never touch SwiftData
    /// (it can outlive the container).
    func scheduleSoftFocusWarning(now: Date = .now) {
        try? templateRepository.seedIfNeeded()
        let planned = PlannedNotification(
            identifier: NotificationConfig.Identifier.softFocusWarning,
            title: notificationTitle(),
            body: phrase(NotificationTemplate.Category.softFocus, on: now),
            afterInterval: 2
        )
        Task { [scheduler] in
            guard await scheduler.isAuthorized() else { return }
            await scheduler.schedule(planned)
        }
    }

    func cancelSoftFocusWarning() {
        scheduler.cancel(identifiers: [NotificationConfig.Identifier.softFocusWarning])
    }

    private func notificationTitle() -> String {
        if let name = try? userProfileRepository.fetchOrCreate().mascotName,
           !name.isEmpty {
            return name
        }
        return String(localized: "notification.defaultTitle")
    }

    private func phrase(_ category: String, on date: Date) -> String {
        let phrases = (try? templateRepository.phrases(category: category)) ?? []
        guard !phrases.isEmpty else {
            return NotificationPhraseCatalog.seeds
                .first { $0.category == category }?.phrase ?? ""
        }
        return phrases[NotificationPlanner.phraseIndex(
            count: phrases.count, on: date, calendar: calendar
        )]
    }
}
