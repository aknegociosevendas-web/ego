import SwiftUI
import os

/// Diagnostic trail for the finish-early flow (slice 6). Remove after the
/// user confirms the fix with a real touch. // LOG(slice6)
private let focusFlowLog = Logger(subsystem: "com.ego.EGO", category: "FocusFlow") // LOG(slice6)

/// Step 2 of the focus flow (F-01): the running timer over the chosen scenery.
/// Configuration moved to `FocusSetupView`; this screen keeps ring + controls
/// and adds a hold-to-finish button. Dumb view — session state lives in
/// `PomodoroViewModel`; the summary step is presented by `FocusFlowView`.
struct FocusTimerView: View {
    @Bindable var viewModel: PomodoroViewModel
    var scenery: FocusScenery = .night
    /// Hold "Concluir": ends the focus now via the existing abandon path
    /// (no rewards) and moves the flow to the summary step.
    var onFinishEarly: () -> Void = {}

    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var showingFinishDialog = false

    var body: some View {
        ZStack {
            AnimatedSceneView(scenery: scenery, animating: viewModel.timerState == .running)
                .ignoresSafeArea()

            VStack(spacing: DS.Spacing.md) {
                header
                Spacer().frame(height: DS.Spacing.md)
                timerBlock
                Spacer()
                controls
            }
            .padding(.horizontal, DS.Spacing.screenPadding)
            .padding(.vertical, DS.Spacing.lg)
        }
        .confirmationDialog(
            "timer.finish.title",
            isPresented: $showingFinishDialog,
            titleVisibility: .visible
        ) {
            Button("timer.finish.confirm", role: .destructive) {
                focusFlowLog.debug("2/6 finish confirmed in dialog → onFinishEarly") // LOG(slice6)
                onFinishEarly()
            }
            .accessibilityIdentifier("finish.confirm")
            Button("timer.finish.cancel", role: .cancel) {}
        } message: {
            Text("timer.finish.message")
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .background: viewModel.appDidEnterBackground()
            case .active: viewModel.appDidBecomeActive()
            default: break
            }
        }
    }

    private var header: some View {
        HStack {
            if canFinishEarly {
                finishEarlyButton
            }
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(DS.Typography.callout)
                    .foregroundStyle(DS.Colors.textPrimary)
                    .frame(width: 40, height: 40)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(Circle().strokeBorder(DS.Colors.borderSubtle, lineWidth: 1))
            }
            .accessibilityLabel(Text("timer.close"))
        }
    }

    // MARK: - Finish early (tap + native confirmation, slice 6)

    private var canFinishEarly: Bool {
        viewModel.phase == .focus && viewModel.timerState != .idle
    }

    private var finishEarlyButton: some View {
        Button {
            focusFlowLog.debug("1/6 Concluir tapped — showing confirmation dialog") // LOG(slice6)
            showingFinishDialog = true
        } label: {
            Text("timer.finishEarly")
                .font(DS.Typography.callout)
                .foregroundStyle(DS.Colors.textPrimary)
                .padding(.horizontal, DS.Spacing.md)
                .frame(minHeight: 44)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().strokeBorder(DS.Colors.borderSubtle, lineWidth: 1))
        }
        .accessibilityLabel(Text("timer.finishEarly"))
    }

    /// Phase label + big countdown with a slim progress ring, legible over the
    /// scene (dark shadow halo keeps contrast on brighter parts).
    private var timerBlock: some View {
        VStack(spacing: DS.Spacing.sm) {
            Text(phaseTitleKey)
                .font(DS.Typography.headline)
                .foregroundStyle(DS.Colors.textPrimary)
                .shadow(color: DS.Colors.bgCanvas.opacity(0.8), radius: 6)

            ZStack {
                ProgressRing(
                    progress: viewModel.progress,
                    tint: viewModel.phase == .focus ? DS.Colors.brandGreen : DS.Colors.accentFocus,
                    lineWidth: 5
                )
                VStack(spacing: DS.Spacing.xxs) {
                    Text(verbatim: viewModel.timeText)
                        .font(DS.Typography.display)
                        .foregroundStyle(DS.Colors.textPrimary)
                        .monospacedDigit()
                        .shadow(color: DS.Colors.bgCanvas.opacity(0.85), radius: 8)
                    Text("timer.cycle \(viewModel.currentCycle) \(viewModel.configuration.cyclesBeforeLongBreak)")
                        .font(DS.Typography.caption)
                        .foregroundStyle(DS.Colors.textPrimary)
                        .shadow(color: DS.Colors.bgCanvas.opacity(0.8), radius: 5)
                }
            }
            .frame(width: 190, height: 190)
        }
    }

    private var controls: some View {
        HStack(spacing: DS.Spacing.xl) {
            Button {
                viewModel.reset()
            } label: {
                controlIcon("arrow.counterclockwise")
            }
            .accessibilityLabel(Text("timer.reset"))
            .disabled(viewModel.timerState == .idle)

            Button {
                primaryAction()
            } label: {
                Image(systemName: primaryIcon)
                    .font(.system(.title, weight: .bold))
                    .foregroundStyle(DS.Colors.textOnBrand)
                    .frame(width: 76, height: 76)
                    .background(DS.Colors.brandGreen)
                    .clipShape(Circle())
            }
            .accessibilityLabel(Text(primaryLabelKey))

            Button {
                viewModel.skip()
            } label: {
                controlIcon("forward.end")
            }
            .accessibilityLabel(Text("timer.skip"))
        }
    }

    // MARK: - Helpers

    private var phaseTitleKey: LocalizedStringKey {
        switch viewModel.phase {
        case .focus: "timer.phase.focus"
        case .shortBreak: "timer.phase.shortBreak"
        case .longBreak: "timer.phase.longBreak"
        }
    }

    private var primaryIcon: String {
        viewModel.timerState == .running ? "pause.fill" : "play.fill"
    }

    private var primaryLabelKey: LocalizedStringKey {
        switch viewModel.timerState {
        case .idle: "timer.start"
        case .running: "timer.pause"
        case .paused: "timer.resume"
        }
    }

    private func primaryAction() {
        switch viewModel.timerState {
        case .idle: viewModel.start()
        case .running: viewModel.pause()
        case .paused: viewModel.resume()
        }
    }

    private func controlIcon(_ systemName: String) -> some View {
        Image(systemName: systemName)
            .font(DS.Typography.headline)
            .foregroundStyle(DS.Colors.textPrimary)
            .frame(width: 52, height: 52)
            .background(.ultraThinMaterial, in: Circle())
            .overlay(Circle().strokeBorder(DS.Colors.borderSubtle, lineWidth: 1))
    }
}

#Preview {
    FocusTimerView(viewModel: DIContainer.preview().makePomodoroViewModel())
}
