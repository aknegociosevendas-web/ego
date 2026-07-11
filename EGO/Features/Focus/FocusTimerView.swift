import SwiftUI

/// F-01 timer screen: ring, controls, subject/preset pickers, and the mascot
/// studying alongside. Dumb view — all state lives in `PomodoroViewModel`.
struct FocusTimerView: View {
    @Bindable var viewModel: PomodoroViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        VStack(spacing: DS.Spacing.lg) {
            header
            Spacer()
            timerRing
            MascotView(state: viewModel.timerMascotState)
                .frame(width: 130, height: 130)
            Spacer()
            if viewModel.timerState == .idle {
                pickers
            }
            controls
        }
        .padding(.horizontal, DS.Spacing.screenPadding)
        .padding(.vertical, DS.Spacing.lg)
        .background(DS.Colors.bgCanvas)
        .sheet(item: $viewModel.sessionSummary) { summary in
            SessionSummaryView(summary: summary)
                .presentationDetents([.medium])
                .presentationCornerRadius(DS.Radius.sheet)
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
        ZStack {
            Text(phaseTitleKey)
                .font(DS.Typography.headline)
                .foregroundStyle(DS.Colors.textPrimary)
            HStack {
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(DS.Typography.callout)
                        .foregroundStyle(DS.Colors.textSecondary)
                }
                .accessibilityLabel(Text("timer.close"))
            }
        }
    }

    private var timerRing: some View {
        ZStack {
            ProgressRing(
                progress: viewModel.progress,
                tint: viewModel.phase == .focus ? DS.Colors.brandGreen : DS.Colors.accentFocus,
                lineWidth: 12
            )
            VStack(spacing: DS.Spacing.xxs) {
                Text(verbatim: viewModel.timeText)
                    .font(DS.Typography.display)
                    .foregroundStyle(DS.Colors.textPrimary)
                    .monospacedDigit()
                Text("timer.cycle \(viewModel.currentCycle) \(viewModel.configuration.cyclesBeforeLongBreak)")
                    .font(DS.Typography.caption)
                    .foregroundStyle(DS.Colors.textSecondary)
            }
        }
        .frame(width: 230, height: 230)
    }

    private var pickers: some View {
        HStack(spacing: DS.Spacing.sm) {
            Menu {
                Button {
                    viewModel.selectedSubject = nil
                } label: {
                    Text("timer.subject.none")
                }
                ForEach(SubjectCatalog.presets, id: \.self) { subject in
                    Button {
                        viewModel.selectedSubject = subject
                    } label: {
                        Text(verbatim: subject)
                    }
                }
            } label: {
                chipLabel(
                    icon: "book.closed",
                    text: viewModel.selectedSubject.map(Text.init(verbatim:)) ?? Text("timer.subject.none")
                )
            }

            Menu {
                ForEach(PomodoroPreset.allCases) { preset in
                    Button {
                        viewModel.configuration = preset.configuration
                    } label: {
                        Text(titleKey(for: preset))
                    }
                }
            } label: {
                chipLabel(icon: "timer", text: Text(titleKey(for: currentPreset)))
            }

            Button {
                viewModel.softFocusEnabled.toggle()
            } label: {
                chipLabel(
                    icon: viewModel.softFocusEnabled ? "shield.fill" : "shield.slash",
                    text: Text("timer.softFocus")
                )
                .foregroundStyle(
                    viewModel.softFocusEnabled ? DS.Colors.accentFocus : DS.Colors.textSecondary
                )
            }
            .accessibilityHint(Text("timer.softFocus.hint"))
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

    private var currentPreset: PomodoroPreset {
        PomodoroPreset.allCases.first { $0.configuration == viewModel.configuration } ?? .standard
    }

    private func titleKey(for preset: PomodoroPreset) -> LocalizedStringKey {
        switch preset {
        case .standard: "timer.preset.standard"
        case .enem: "timer.preset.enem"
        case .deep: "timer.preset.deep"
        }
    }

    private func controlIcon(_ systemName: String) -> some View {
        Image(systemName: systemName)
            .font(DS.Typography.headline)
            .foregroundStyle(DS.Colors.textPrimary)
            .frame(width: 52, height: 52)
            .background(DS.Colors.bgSurface)
            .clipShape(Circle())
            .overlay(Circle().strokeBorder(DS.Colors.borderSubtle, lineWidth: 1))
    }

    private func chipLabel(icon: String, text: Text) -> some View {
        HStack(spacing: DS.Spacing.xxs) {
            Image(systemName: icon)
                .font(DS.Typography.caption)
            text
                .font(DS.Typography.callout)
        }
        .foregroundStyle(DS.Colors.textPrimary)
        .padding(.horizontal, DS.Spacing.sm)
        .padding(.vertical, DS.Spacing.xs)
        .background(DS.Colors.bgSurfaceAlt)
        .clipShape(Capsule())
    }
}

#Preview {
    FocusTimerView(viewModel: DIContainer.preview().makePomodoroViewModel())
}
