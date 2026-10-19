import SwiftUI
import os

private let focusFlowLog = Logger(subsystem: "com.ego.EGO", category: "FocusFlow") // LOG(slice6)

/// Container for the 3-step focus flow (F-01 redesign, slice 4):
/// setup → timer → summary, inside one full-screen cover. Owns flow-only
/// state (step, free-text label, scenery); all session state stays in the
/// shared `PomodoroViewModel` — the state machine is untouched.
struct FocusFlowView: View {
    @Bindable var viewModel: PomodoroViewModel
    /// Fresh unlocks of the finished session, reported when the summary
    /// closes so the milestone card can present over the Home (slice 7).
    var onMilestones: (SessionCompletionService.Result) -> Void = { _ in }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage(FocusScenery.storageKey) private var sceneryRaw = FocusScenery.night.rawValue
    @State private var step: Step = .setup
    @State private var focusLabel = ""
    @State private var summaryPayload: FocusSummaryPayload?

    private enum Step {
        case setup, timer, summary
    }

    private var scenery: Binding<FocusScenery> {
        Binding(
            // Also migrates slice-4 values (nightLake/forest/swamp) → .night.
            get: { FocusScenery.from(storageValue: sceneryRaw) },
            set: { sceneryRaw = $0.rawValue }
        )
    }

    var body: some View {
        Group {
            switch step {
            case .setup:
                FocusSetupView(
                    viewModel: viewModel,
                    focusLabel: $focusLabel,
                    scenery: scenery,
                    onStart: {
                        viewModel.start()
                        advance(to: .timer)
                    }
                )
            case .timer:
                FocusTimerView(
                    viewModel: viewModel,
                    scenery: scenery.wrappedValue,
                    onFinishEarly: finishEarly
                )
            case .summary:
                if let summaryPayload {
                    SessionSummaryView(
                        payload: summaryPayload,
                        scenery: scenery.wrappedValue,
                        focusLabel: focusLabel,
                        subject: viewModel.selectedSubject,
                        onContinue: { finishFlow() },
                        onTakeBreak: { advance(to: .timer) }
                    )
                }
            }
        }
        .onChange(of: viewModel.sessionSummary) { _, summary in
            guard let summary else { return }
            focusFlowLog.debug("7/7 sessionSummary observed (completed path), step → summary") // LOG(slice6)
            // The flow presents the summary as its own step, not a sheet.
            viewModel.sessionSummary = nil
            summaryPayload = .completed(summary)
            advance(to: .summary)
        }
        .onAppear {
            // Reopening mid-run (or mid-cycle at a break) skips the setup.
            if viewModel.timerState != .idle || viewModel.phase != .focus {
                step = .timer
            }
        }
    }

    /// Summary's "Continuar": report fresh unlocks (milestone card) and close
    /// the flow.
    private func finishFlow() {
        if case .completed(let summary) = summaryPayload {
            onMilestones(summary.result)
        }
        dismiss()
    }

    private func advance(to next: Step) {
        if reduceMotion {
            step = next
        } else {
            withAnimation(.easeInOut(duration: 0.25)) {
                step = next
            }
        }
    }

    /// Finish early (confirmed in the timer's dialog): capture the elapsed
    /// minutes, then run the existing abandon path (no rewards) and show the
    /// summary.
    private func finishEarly() {
        let minutes = Int((viewModel.phaseDuration - viewModel.remaining) / 60)
        focusFlowLog.debug("3/6 finishEarly entered, elapsed=\(minutes)min") // LOG(slice6)
        viewModel.reset()
        focusFlowLog.debug("4/6 viewModel.reset() returned (abandon path ran)") // LOG(slice6)
        summaryPayload = .endedEarly(minutes: minutes)
        advance(to: .summary)
        focusFlowLog.debug("5/6 summaryPayload set (.endedEarly), step → summary") // LOG(slice6)
    }
}

#Preview {
    FocusFlowView(viewModel: DIContainer.preview().makePomodoroViewModel())
}
