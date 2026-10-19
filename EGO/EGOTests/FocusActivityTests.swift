import Foundation
import Testing
@testable import EGO

/// Records Live Activity calls (ActivityKit can't run in unit tests).
@MainActor
final class SpyFocusActivityController: FocusActivityManaging {
    struct Start: Equatable {
        let phase: String
        let subject: String?
        let streakCount: Int
    }

    struct Update: Equatable {
        let phase: String
        let isPaused: Bool
    }

    var starts: [Start] = []
    var updates: [Update] = []
    var endCount = 0

    func startActivity(phase: String, endDate: Date, subject: String?, streakCount: Int) {
        starts.append(Start(phase: phase, subject: subject, streakCount: streakCount))
    }

    func updateActivity(phase: String, endDate: Date, isPaused: Bool, pausedRemaining: TimeInterval?) {
        updates.append(Update(phase: phase, isPaused: isPaused))
    }

    func endActivity() {
        endCount += 1
    }
}

@MainActor
struct FocusActivityTests {
    func makeViewModel() throws -> (PomodoroViewModel, SpyFocusActivityController, DIContainer) {
        let container = try PersistenceController.makeInMemoryContainer()
        let di = DIContainer(modelContainer: container)
        let spy = SpyFocusActivityController()
        let viewModel = PomodoroViewModel(
            completionService: di.sessionCompletionService,
            mascotEvents: di.mascotEvents,
            streakRepository: di.streakRepository,
            goalRepository: di.topicGoalRepository,
            activityController: spy,
            notificationService: di.notificationService
        )
        return (viewModel, spy, di)
    }

    @Test func startingFocusStartsActivityWithSubjectAndStreak() throws {
        let (viewModel, spy, di) = try makeViewModel()
        let streak = try di.streakRepository.fetchOrCreate()
        streak.current = 7
        try di.streakRepository.save()
        viewModel.selectedSubject = "Matemática"

        viewModel.start()

        #expect(spy.starts == [SpyFocusActivityController.Start(
            phase: "focus", subject: "Matemática", streakCount: 7
        )])
    }

    @Test func pauseAndResumeUpdateTheActivity() throws {
        // `di` owns the in-memory ModelContainer — it must outlive the VM calls.
        let (viewModel, spy, di) = try makeViewModel()
        defer { withExtendedLifetime(di) {} }

        viewModel.start()
        viewModel.pause()
        viewModel.resume()

        #expect(spy.updates == [
            SpyFocusActivityController.Update(phase: "focus", isPaused: true),
            SpyFocusActivityController.Update(phase: "focus", isPaused: false),
        ])
    }

    @Test func resetEndsTheActivity() throws {
        let (viewModel, spy, di) = try makeViewModel()
        defer { withExtendedLifetime(di) {} }

        viewModel.start()
        viewModel.reset()

        #expect(spy.endCount >= 1)
        #expect(viewModel.timerState == .idle)
    }

    @Test func completingFocusEndsTheActivity() async throws {
        let (viewModel, spy, di) = try makeViewModel()
        defer { withExtendedLifetime(di) {} }
        viewModel.configuration = PomodoroConfiguration(
            focusMinutes: 0, shortBreakMinutes: 0, longBreakMinutes: 0, cyclesBeforeLongBreak: 4
        )

        viewModel.start()
        // Zero-length focus completes on the first ticker pass (~500ms).
        try await Task.sleep(for: .milliseconds(1200))

        #expect(viewModel.phase == .shortBreak)
        #expect(viewModel.timerState == .idle)
        #expect(spy.endCount >= 1)
    }

    @Test func startingBreakStartsBreakActivity() throws {
        let (viewModel, spy, di) = try makeViewModel()
        defer { withExtendedLifetime(di) {} }

        viewModel.skip() // idle focus → short break, no abandon
        viewModel.start()

        #expect(spy.starts.last?.phase == "shortBreak")
        #expect(spy.starts.last?.subject == nil)
    }
}
