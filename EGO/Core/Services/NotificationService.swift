import Foundation

/// Orchestrates F-03/F-09 + the slice-7 motivational system: reads state from
/// repositories, plans via the pure planners, applies via the scheduler.
/// Re-planning always replaces pending requests (fixed identifiers) and runs
/// on launch and every time the app leaves the foreground.
@MainActor
final class NotificationService {
    private let scheduler: NotificationScheduling
    private let reminderRepository: ReminderRepository
    private let templateRepository: NotificationTemplateRepository
    private let streakRepository: StreakRepository
    private let userStatsRepository: UserStatsRepository
    private let userProfileRepository: UserProfileRepository
    private let focusRepository: FocusRepository
    private let phraseSelector: MotivationalPhraseSelectorProtocol
    private let settingsStore: NotificationSettingsStore
    private let config: NotificationConfig
    private let calendar: Calendar

    init(
        scheduler: NotificationScheduling,
        reminderRepository: ReminderRepository,
        templateRepository: NotificationTemplateRepository,
        streakRepository: StreakRepository,
        userStatsRepository: UserStatsRepository,
        userProfileRepository: UserProfileRepository,
        focusRepository: FocusRepository,
        phraseSelector: MotivationalPhraseSelectorProtocol,
        settingsStore: NotificationSettingsStore,
        config: NotificationConfig = .standard,
        calendar: Calendar = .current
    ) {
        self.scheduler = scheduler
        self.reminderRepository = reminderRepository
        self.templateRepository = templateRepository
        self.streakRepository = streakRepository
        self.userStatsRepository = userStatsRepository
        self.userProfileRepository = userProfileRepository
        self.focusRepository = focusRepository
        self.phraseSelector = phraseSelector
        self.settingsStore = settingsStore
        self.config = config
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

    func isAuthorized() async -> Bool {
        await scheduler.isAuthorized()
    }

    /// Re-plans everything from current state. Called on launch and on scene
    /// background.
    func refreshSchedules(now: Date = .now) async {
        guard await scheduler.isAuthorized() else { return }
        try? templateRepository.seedIfNeeded()
        let title = notificationTitle()

        // 1. Daily session reminder (F-09). User-created, exempt from the
        // motivational rate limit.
        scheduler.cancel(identifiers: [NotificationConfig.Identifier.sessionReminder])
        if let reminder = try? reminderRepository.sessionReminder(),
           reminder.enabled,
           settingsStore.isEnabled(.sessionReminder),
           let time = reminder.time {
            let components = calendar.dateComponents([.hour, .minute], from: time)
            let phrase = motivationalPhrase(for: .sessionReminder)
            var planned = NotificationPlanner.sessionReminder(
                hour: components.hour ?? config.defaultReminderHour,
                minute: components.minute ?? 0,
                title: title,
                body: phrase?.body ?? legacyPhrase(NotificationTemplate.Category.reminder, on: now),
                config: config
            )
            planned.userInfo = deepLinkUserInfo(category: .sessionReminder, phraseId: phrase?.id)
            await scheduler.schedule(planned)
        }

        // 2. Motivational one-shots (slice 7): cancel-and-replan, including
        // the pre-slice-7 identifiers so migration leaves nothing stale.
        scheduler.cancel(identifiers: NotificationConfig.Identifier.allMotivational + [
            NotificationConfig.Identifier.legacyStreakRisk,
            NotificationConfig.Identifier.legacyComeback,
        ])
        for slot in MotivationalNotificationPlanner.plan(plannerContext(now: now)) {
            guard let phrase = motivationalPhrase(for: slot.category) else { continue }
            await scheduler.schedule(PlannedNotification(
                identifier: slot.identifier,
                title: title,
                body: phrase.body,
                dateComponents: calendar.dateComponents(
                    [.year, .month, .day, .hour, .minute], from: slot.fireDate
                ),
                userInfo: deepLinkUserInfo(category: slot.category, phraseId: phrase.id)
            ))
        }
    }

    /// Today qualified: risk nudges and today's afternoon push are moot.
    /// Everything else is re-planned on scene background.
    func sessionDidComplete() {
        scheduler.cancel(identifiers: [
            NotificationConfig.Identifier.motivationalStreakRisk1,
            NotificationConfig.Identifier.motivationalStreakRisk2,
            NotificationConfig.Identifier.motivationalAfternoon,
            NotificationConfig.Identifier.legacyStreakRisk,
        ])
    }

    /// Foreground entry: the morning nudge is moot, and opening the app soon
    /// after a delivered motivational suppresses new ones for a while
    /// (anti-spam, slice 7).
    func appDidBecomeActive(now: Date = .now) async {
        scheduler.cancel(identifiers: [NotificationConfig.Identifier.motivationalMorning])
        let delivered = await scheduler.deliveredDates(
            identifierPrefix: NotificationConfig.Identifier.motivationalPrefix
        )
        guard let latest = delivered.max() else { return }
        settingsStore.lastMotivationalDeliveredAt = latest
        if now.timeIntervalSince(latest) <= config.antiSpamOpenWindow {
            settingsStore.suppressedUntil = now.addingTimeInterval(config.antiSpamSuppression)
        }
    }

    /// Settings › "Testar notificação": fires a generic phrase in 5 seconds.
    /// Returns false when notifications aren't authorized.
    @discardableResult
    func sendTestNotification() async -> Bool {
        guard await scheduler.isAuthorized() else { return false }
        guard let phrase = motivationalPhrase(for: .generic) else { return false }
        await scheduler.schedule(PlannedNotification(
            identifier: NotificationConfig.Identifier.motivationalTest,
            title: notificationTitle(),
            body: phrase.body,
            afterInterval: 5,
            userInfo: deepLinkUserInfo(category: .generic, phraseId: phrase.id)
        ))
        return true
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
            body: legacyPhrase(NotificationTemplate.Category.softFocus, on: now),
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

    // MARK: - Planner input

    private func plannerContext(now: Date) -> MotivationalNotificationPlanner.Context {
        let today = calendar.startOfDay(for: now)
        let completedToday = ((try? focusRepository.completedSessions(
            in: DateInterval(start: today, duration: 86_400)
        )) ?? []).isEmpty == false
        let streak = try? streakRepository.fetchOrCreate()
        let stats = try? userStatsRepository.fetchOrCreate()
        return MotivationalNotificationPlanner.Context(
            now: now,
            calendar: calendar,
            quietStartMinutes: settingsStore.quietStartMinutes,
            quietEndMinutes: settingsStore.quietEndMinutes,
            enabled: settingsStore.enabledCategories,
            suppressedUntil: settingsStore.suppressedUntil,
            lastActiveDay: stats?.lastActiveDay,
            hasCompletedSessionToday: completedToday,
            streakCurrent: streak?.current ?? 0,
            lastQualifiedDay: streak?.lastQualifiedDay,
            usualStartHour: usualStartHour(),
            config: config
        )
    }

    /// Mean start hour of the last 20 completed sessions (comeback heuristic).
    private func usualStartHour() -> Int? {
        let starts = ((try? focusRepository.fetchAll()) ?? [])
            .filter(\.completed)
            .compactMap(\.startedAt)
            .sorted(by: >)
            .prefix(20)
        guard !starts.isEmpty else { return nil }
        let hours = starts.map { calendar.component(.hour, from: $0) }
        return Int((Double(hours.reduce(0, +)) / Double(hours.count)).rounded())
    }

    // MARK: - Phrases

    private func motivationalPhrase(
        for category: NotificationCategory
    ) -> (body: String, id: String?)? {
        guard let template = try? phraseSelector.select(for: category),
              let body = template.phrase, !body.isEmpty
        else { return nil }
        return (body, template.key)
    }

    private func deepLinkUserInfo(
        category: NotificationCategory, phraseId: String?
    ) -> [String: String] {
        var info = ["category": category.rawValue]
        if let phraseId { info["phraseId"] = phraseId }
        return info
    }

    private func notificationTitle() -> String {
        if let name = try? userProfileRepository.fetchOrCreate().mascotName,
           !name.isEmpty {
            return name
        }
        return String(localized: "notification.defaultTitle")
    }

    /// Pre-slice-7 catalog rotation (softFocus + reminder fallback).
    private func legacyPhrase(_ category: String, on date: Date) -> String {
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
