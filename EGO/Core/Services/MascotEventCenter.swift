import Foundation
import Observation

/// App-event → mascot-state hub (golden rule: the mascot reacts to events).
/// Services publish events; views only read `state`. Transient reactions
/// (celebrate/sad) revert to the current baseline — `.idle`, or `.worried`
/// while the streak is at risk.
@MainActor
@Observable
final class MascotEventCenter {
    private(set) var state: MascotState = .idle
    /// Resting state the mascot returns to when nothing else is happening.
    private(set) var baseline: MascotState = .idle
    @ObservationIgnored private var revertTask: Task<Void, Never>?

    /// Seconds a celebration/sad reaction stays before reverting (injectable
    /// so tests don't wait 4 real seconds).
    private let reactionDuration: TimeInterval

    init(reactionDuration: TimeInterval = 4) {
        self.reactionDuration = reactionDuration
    }

    /// `.idle` or `.worried`. Doesn't interrupt studying or a running flash.
    func updateBaseline(_ newBaseline: MascotState) {
        let previous = baseline
        baseline = newBaseline
        if state == previous, revertTask == nil {
            state = newBaseline
        }
    }

    func focusStarted() {
        cancelRevert()
        state = .studying
    }

    func focusStopped() {
        cancelRevert()
        state = baseline
    }

    func sessionCompleted() {
        flash(.happy)
    }

    func sessionAbandoned() {
        flash(.sad)
    }

    func leveledUp() {
        flash(.levelUp)
    }

    /// 3+ correct answers in a row (F-07 hook).
    func questionStreak() {
        flash(.happy)
    }

    /// Essay finished (F-08 hook).
    func essayFinished() {
        flash(.happy)
    }

    /// Topic goal completed (F-10 hook).
    func goalCompleted() {
        flash(.happy)
    }

    private func flash(_ newState: MascotState) {
        cancelRevert()
        state = newState
        revertTask = Task { [weak self, reactionDuration] in
            try? await Task.sleep(for: .seconds(reactionDuration))
            guard !Task.isCancelled else { return }
            self?.finishFlash()
        }
    }

    private func finishFlash() {
        revertTask = nil
        state = baseline
    }

    private func cancelRevert() {
        revertTask?.cancel()
        revertTask = nil
    }
}
