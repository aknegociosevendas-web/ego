import Foundation

/// Timer durations and cycle count (F-01). UI-free so ViewModels/tests can
/// use it without SwiftUI.
struct PomodoroConfiguration: Equatable, Sendable {
    var focusMinutes = 25
    var shortBreakMinutes = 5
    var longBreakMinutes = 15
    var cyclesBeforeLongBreak = 4

    static let standard = PomodoroConfiguration()
    static let enem = PomodoroConfiguration(
        focusMinutes: 50, shortBreakMinutes: 10, longBreakMinutes: 20, cyclesBeforeLongBreak: 2
    )
    static let deep = PomodoroConfiguration(
        focusMinutes: 90, shortBreakMinutes: 20, longBreakMinutes: 30, cyclesBeforeLongBreak: 2
    )
}

/// Built-in presets (docs/01 F-01). The view maps cases to localized titles.
enum PomodoroPreset: CaseIterable, Identifiable {
    case standard, enem, deep

    var id: Self { self }

    var configuration: PomodoroConfiguration {
        switch self {
        case .standard: .standard
        case .enem: .enem
        case .deep: .deep
        }
    }
}
