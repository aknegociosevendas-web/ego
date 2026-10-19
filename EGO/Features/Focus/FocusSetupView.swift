import SwiftUI

/// Step 1 of the focus flow (F-01 redesign, slice 4): configure the session
/// before the timer. Reorganizes what already lived on the timer screen —
/// goal, subject, preset, soft focus ("Foco profundo") — plus the new scenery
/// picker and an optional free-text label. Dumb view: session state stays in
/// `PomodoroViewModel`; flow-only state (label, scenery) is owned by
/// `FocusFlowView` and passed as bindings.
struct FocusSetupView: View {
    @Bindable var viewModel: PomodoroViewModel
    @Binding var focusLabel: String
    @Binding var scenery: FocusScenery
    var onStart: () -> Void

    @Environment(\.dismiss) private var dismiss
    /// The deep-focus explainer alert shows once, then the toggle is instant.
    @AppStorage("deepFocusAlertSeen") private var deepFocusAlertSeen = false
    @State private var showingSceneryPicker = false
    @State private var showingDeepFocusAlert = false

    var body: some View {
        ZStack {
            // Static preview of the chosen scenery (frame 00; the frog and rig
            // are part of the art). Animation only starts with the session.
            AnimatedSceneView(scenery: scenery, animating: false)
                .ignoresSafeArea()

            VStack(spacing: DS.Spacing.md) {
                header
                Spacer()
                panel
            }
            .padding(.horizontal, DS.Spacing.screenPadding)
            .padding(.vertical, DS.Spacing.lg)
        }
        .sheet(isPresented: $showingSceneryPicker) {
            ScenePickerView(selection: $scenery)
                .presentationDetents([.medium])
                .presentationCornerRadius(DS.Radius.sheet)
        }
        .alert("setup.deepFocus.alertTitle", isPresented: $showingDeepFocusAlert) {
            Button("setup.deepFocus.alertConfirm") {
                deepFocusAlertSeen = true
                viewModel.softFocusEnabled = true
            }
            Button("setup.deepFocus.alertCancel", role: .cancel) {}
        } message: {
            Text("setup.deepFocus.alertMessage")
        }
        .onAppear {
            viewModel.refreshGoals()
        }
    }

    private var header: some View {
        HStack {
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

    // MARK: - Config panel

    private var panel: some View {
        VStack(spacing: DS.Spacing.md) {
            questionCard
            chips
            startButton
            quickBar
        }
        .padding(DS.Spacing.md)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DS.Radius.sheet))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.sheet)
                .strokeBorder(DS.Colors.borderSubtle.opacity(0.6), lineWidth: 1)
        )
    }

    private var questionCard: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
            Text("setup.question")
                .font(DS.Typography.headline)
                .foregroundStyle(DS.Colors.textPrimary)
            TextField("setup.questionPlaceholder", text: $focusLabel)
                .font(DS.Typography.callout)
                .foregroundStyle(DS.Colors.textPrimary)
                .padding(.horizontal, DS.Spacing.sm)
                .padding(.vertical, DS.Spacing.xs)
                .background(DS.Colors.bgSurface.opacity(0.55), in: Capsule())
                .overlay(Capsule().strokeBorder(DS.Colors.borderSubtle, lineWidth: 1))
                .submitLabel(.done)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Goal + subject pickers (moved from the timer screen, same behavior:
    /// an attached goal drives and locks the subject).
    private var chips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DS.Spacing.sm) {
                goalChip
                subjectChip
            }
            .padding(.horizontal, DS.Spacing.xxs)
        }
    }

    private var goalChip: some View {
        Menu {
            Button {
                viewModel.selectGoal(nil)
            } label: {
                Text("timer.goal.none")
            }
            ForEach(viewModel.availableGoals) { goal in
                Button {
                    viewModel.selectGoal(goal.id)
                } label: {
                    Text(verbatim: goal.subject.isEmpty || goal.subject == goal.title
                        ? goal.title
                        : "\(goal.title) · \(goal.subject)")
                }
            }
        } label: {
            chipLabel(
                icon: "target",
                text: viewModel.selectedGoal.map { Text(verbatim: $0.title) } ?? Text("timer.goal.none")
            )
            .foregroundStyle(
                viewModel.selectedGoal == nil ? DS.Colors.textPrimary : DS.Colors.brandGreenDeep
            )
        }
        .accessibilityHint(Text("timer.goal.hint"))
    }

    private var subjectChip: some View {
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
        .disabled(viewModel.isSubjectLockedByGoal)
        .opacity(viewModel.isSubjectLockedByGoal ? 0.5 : 1)
        .accessibilityHint(
            viewModel.isSubjectLockedByGoal
                ? Text("timer.subject.lockedHint")
                : Text("")
        )
    }

    /// The big "Go": starts the session and hands off to the timer step.
    private var startButton: some View {
        Button {
            onStart()
        } label: {
            Text("timer.start")
                .font(DS.Typography.headline)
                .foregroundStyle(DS.Colors.textOnBrand)
                .frame(width: 108, height: 108)
                .background(DS.Colors.brandGreen, in: Circle())
                .overlay(
                    Circle()
                        .strokeBorder(DS.Colors.brandGreenSoft.opacity(0.5), lineWidth: 3)
                        .padding(4)
                )
        }
        .accessibilityLabel(Text("timer.start"))
    }

    // MARK: - Quick adjustments (time · scenery · deep focus)

    private var quickBar: some View {
        HStack(spacing: DS.Spacing.sm) {
            timeOption
            sceneryOption
            deepFocusOption
        }
    }

    private var timeOption: some View {
        Menu {
            ForEach(PomodoroPreset.allCases) { preset in
                Button {
                    viewModel.configuration = preset.configuration
                } label: {
                    Text(titleKey(for: preset))
                }
            }
        } label: {
            quickOptionLabel(
                icon: "timer",
                titleKey: "setup.time",
                detail: Text(titleKey(for: currentPreset)),
                active: false
            )
        }
    }

    private var sceneryOption: some View {
        Button {
            showingSceneryPicker = true
        } label: {
            quickOptionLabel(
                icon: "photo",
                titleKey: "setup.scenery",
                detail: Text(scenery.titleKey),
                active: false
            )
        }
    }

    private var deepFocusOption: some View {
        Button {
            if viewModel.softFocusEnabled {
                viewModel.softFocusEnabled = false
            } else if deepFocusAlertSeen {
                viewModel.softFocusEnabled = true
            } else {
                showingDeepFocusAlert = true
            }
        } label: {
            quickOptionLabel(
                icon: viewModel.softFocusEnabled ? "shield.fill" : "shield.slash",
                titleKey: "setup.deepFocus",
                detail: Text(viewModel.softFocusEnabled ? "setup.deepFocus.on" : "setup.deepFocus.off"),
                active: viewModel.softFocusEnabled
            )
        }
        .accessibilityHint(Text("setup.deepFocus.hint"))
    }

    private func quickOptionLabel(
        icon: String,
        titleKey: LocalizedStringKey,
        detail: Text,
        active: Bool
    ) -> some View {
        VStack(spacing: DS.Spacing.xxs) {
            Image(systemName: icon)
                .font(DS.Typography.headline)
                .foregroundStyle(active ? DS.Colors.accentFocus : DS.Colors.textPrimary)
            Text(titleKey)
                .font(DS.Typography.caption)
                .foregroundStyle(DS.Colors.textPrimary)
            detail
                .font(DS.Typography.caption)
                .foregroundStyle(DS.Colors.textSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DS.Spacing.xs)
        .background(DS.Colors.bgSurface.opacity(0.35), in: RoundedRectangle(cornerRadius: DS.Radius.card))
    }

    // MARK: - Helpers (shared wording with the timer screen)

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
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(DS.Colors.borderSubtle, lineWidth: 1))
    }
}

#Preview {
    FocusSetupView(
        viewModel: DIContainer.preview().makePomodoroViewModel(),
        focusLabel: .constant(""),
        scenery: .constant(.night),
        onStart: {}
    )
}
