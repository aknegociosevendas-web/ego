import Foundation
import Observation

/// Payload for the post-session feedback sheet.
struct CompletedSessionSummary: Identifiable, Equatable {
    let id = UUID()
    let minutes: Int
    let result: SessionCompletionService.Result
}

/// F-01 state machine. Date-based math (`endDate`), so the countdown stays
/// correct across pauses in UI updates; a light ticker only detects completion.
@MainActor
@Observable
final class PomodoroViewModel {
    enum Phase: Equatable {
        case focus, shortBreak, longBreak
    }

    enum TimerState: Equatable {
        case idle, running, paused
    }

    var configuration: PomodoroConfiguration = .standard
    var selectedSubject: String?
    /// Soft-focus honor mode (docs/06 §7): leaving the app mid-focus beyond
    /// the grace window abandons the session.
    var softFocusEnabled = true

    private(set) var phase: Phase = .focus
    private(set) var timerState: TimerState = .idle
    private(set) var completedFocusCount = 0
    /// Set when a focus completes; the view presents it as a summary sheet.
    var sessionSummary: CompletedSessionSummary?

    private(set) var now: Date = .now
    private var endDate: Date?
    private var pausedRemaining: TimeInterval?
    private var focusStartedAt: Date?
    /// When the user left the app during a soft-focus run.
    private var leftAt: Date?
    @ObservationIgnored private var tickerTask: Task<Void, Never>?

    private let completionService: SessionCompletionService
    private let mascotEvents: MascotEventCenter
    private let streakRepository: StreakRepository
    private let activityController: FocusActivityManaging
    private let notificationService: NotificationService
    private let config: GamificationConfig

    init(
        completionService: SessionCompletionService,
        mascotEvents: MascotEventCenter,
        streakRepository: StreakRepository,
        activityController: FocusActivityManaging,
        notificationService: NotificationService,
        config: GamificationConfig = .standard
    ) {
        self.completionService = completionService
        self.mascotEvents = mascotEvents
        self.streakRepository = streakRepository
        self.activityController = activityController
        self.notificationService = notificationService
        self.config = config
    }

    // MARK: - Derived state

    var mascotState: MascotState { mascotEvents.state }

    /// Timer-local mascot: guards while the soft-focus shield is armed.
    var timerMascotState: MascotState {
        if softFocusEnabled, phase == .focus, timerState == .running {
            .guarding
        } else {
            mascotEvents.state
        }
    }

    var phaseDuration: TimeInterval {
        let minutes = switch phase {
        case .focus: configuration.focusMinutes
        case .shortBreak: configuration.shortBreakMinutes
        case .longBreak: configuration.longBreakMinutes
        }
        return TimeInterval(minutes * 60)
    }

    var remaining: TimeInterval {
        switch timerState {
        case .idle: phaseDuration
        case .paused: pausedRemaining ?? phaseDuration
        case .running: max(0, endDate?.timeIntervalSince(now) ?? 0)
        }
    }

    var progress: Double {
        guard phaseDuration > 0 else { return 0 }
        return 1 - remaining / phaseDuration
    }

    var timeText: String {
        let seconds = Int(remaining.rounded())
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    /// 1-based cycle position for "Ciclo X de Y".
    var currentCycle: Int {
        completedFocusCount % configuration.cyclesBeforeLongBreak + 1
    }

    // MARK: - Actions

    func start() {
        guard timerState == .idle else { return }
        let startDate = Date.now
        now = startDate
        let end = startDate.addingTimeInterval(phaseDuration)
        endDate = end
        timerState = .running
        if phase == .focus {
            focusStartedAt = startDate
            mascotEvents.focusStarted()
        }
        activityController.startActivity(
            phase: phaseKey,
            endDate: end,
            subject: phase == .focus ? selectedSubject : nil,
            streakCount: (try? streakRepository.fetchOrCreate().current) ?? 0
        )
        startTicker()
    }

    func pause() {
        guard timerState == .running else { return }
        now = .now
        pausedRemaining = remaining
        timerState = .paused
        stopTicker()
        if phase == .focus {
            mascotEvents.focusStopped()
        }
        activityController.updateActivity(
            phase: phaseKey,
            endDate: endDate ?? now,
            isPaused: true,
            pausedRemaining: pausedRemaining
        )
    }

    func resume() {
        guard timerState == .paused, let remaining = pausedRemaining else { return }
        now = .now
        let end = now.addingTimeInterval(remaining)
        endDate = end
        pausedRemaining = nil
        timerState = .running
        if phase == .focus {
            mascotEvents.focusStarted()
        }
        activityController.updateActivity(
            phase: phaseKey,
            endDate: end,
            isPaused: false,
            pausedRemaining: nil
        )
        startTicker()
    }

    /// Skipping a started focus abandons it (no rewards); breaks just advance.
    func skip() {
        abandonFocusIfStarted()
        stopTicker()
        advance(afterCompletedFocus: false)
    }

    /// Back to a full current phase; abandons a started focus.
    func reset() {
        abandonFocusIfStarted()
        stopTicker()
        clearTimer()
    }

    // MARK: - Soft focus (docs/06 §7)

    func appDidEnterBackground(at date: Date = .now) {
        guard softFocusEnabled, phase == .focus, timerState == .running else { return }
        leftAt = date
        notificationService.scheduleSoftFocusWarning()
    }

    func appDidBecomeActive(at date: Date = .now) {
        notificationService.cancelSoftFocusWarning()
        guard let left = leftAt else { return }
        leftAt = nil
        guard softFocusEnabled, phase == .focus, timerState == .running else { return }
        if date.timeIntervalSince(left) > config.softFocusGraceSeconds {
            abandonSoftFocusViolation(leftAt: left)
        }
    }

    /// Left beyond the grace window: honor-mode penalty — the session is
    /// abandoned (no rewards, day doesn't qualify), counting only the
    /// minutes focused before leaving.
    private func abandonSoftFocusViolation(leftAt left: Date) {
        stopTicker()
        let remainingAtLeave = max(0, endDate?.timeIntervalSince(left) ?? 0)
        let elapsedMinutes = Int((phaseDuration - remainingAtLeave) / 60)
        if elapsedMinutes >= 1 {
            let session = FocusSession(
                startedAt: focusStartedAt,
                plannedMinutes: configuration.focusMinutes,
                type: .focus,
                subject: selectedSubject
            )
            session.actualMinutes = elapsedMinutes
            try? completionService.abandonSession(session)
        } else {
            mascotEvents.focusStopped()
        }
        clearTimer()
    }

    // MARK: - Ticking

    private func startTicker() {
        tickerTask?.cancel()
        tickerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(500))
                self?.handleTick()
            }
        }
    }

    private func stopTicker() {
        tickerTask?.cancel()
        tickerTask = nil
    }

    private func handleTick() {
        now = .now
        // A pending soft-focus violation is resolved in appDidBecomeActive;
        // never let the timer complete underneath it.
        guard leftAt == nil else { return }
        guard timerState == .running, let end = endDate, now >= end else { return }
        stopTicker()
        if phase == .focus {
            completeFocus()
        } else {
            advance(afterCompletedFocus: false)
        }
    }

    // MARK: - Transitions

    private func completeFocus() {
        let session = FocusSession(
            startedAt: focusStartedAt,
            plannedMinutes: configuration.focusMinutes,
            type: .focus,
            subject: selectedSubject
        )
        session.actualMinutes = configuration.focusMinutes
        if let result = try? completionService.completeSession(session) {
            sessionSummary = CompletedSessionSummary(
                minutes: session.actualMinutes,
                result: result
            )
        }
        completedFocusCount += 1
        advance(afterCompletedFocus: true)
    }

    private func abandonFocusIfStarted() {
        guard phase == .focus, timerState != .idle else { return }
        now = .now
        let elapsedMinutes = Int((phaseDuration - remaining) / 60)
        if elapsedMinutes >= 1 {
            let session = FocusSession(
                startedAt: focusStartedAt,
                plannedMinutes: configuration.focusMinutes,
                type: .focus,
                subject: selectedSubject
            )
            session.actualMinutes = elapsedMinutes
            try? completionService.abandonSession(session)
        } else {
            // Too short to count as a quit — no guilt, back to idle.
            mascotEvents.focusStopped()
        }
    }

    private func advance(afterCompletedFocus completed: Bool) {
        if phase == .focus {
            let longBreakDue = completed
                && completedFocusCount > 0
                && completedFocusCount % configuration.cyclesBeforeLongBreak == 0
            phase = longBreakDue ? .longBreak : .shortBreak
        } else {
            phase = .focus
        }
        clearTimer()
    }

    private func clearTimer() {
        timerState = .idle
        endDate = nil
        pausedRemaining = nil
        focusStartedAt = nil
        leftAt = nil
        now = .now
        // The Live Activity only lives while a timer runs (F-16).
        activityController.endActivity()
    }

    /// Phase key shared with the Live Activity contract.
    private var phaseKey: String {
        switch phase {
        case .focus: "focus"
        case .shortBreak: "shortBreak"
        case .longBreak: "longBreak"
        }
    }
}
