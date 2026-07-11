import ActivityKit
import SwiftUI
import WidgetKit

/// F-16: the running Pomodoro on the Lock Screen and Dynamic Island.
/// The countdown is system-driven (`Text(timerInterval:)`) — no pushes needed.
struct FocusLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusActivityAttributes.self) { context in
            FocusLockScreenView(context: context)
                .activityBackgroundTint(DS.Colors.bgSurface)
                .activitySystemActionForegroundColor(DS.Colors.brandGreen)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    MascotStamp(state: context.state)
                        .frame(width: 44, height: 44)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: DS.Spacing.xxs) {
                        Text(phaseTitleKey(context.state.phase))
                            .font(DS.Typography.caption)
                            .foregroundStyle(DS.Colors.textSecondary)
                        CountdownText(state: context.state)
                            .font(DS.Typography.title)
                            .foregroundStyle(phaseTint(context.state.phase))
                            .monospacedDigit()
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    StreakStamp(count: context.attributes.streakCount)
                }
            } compactLeading: {
                Image(systemName: "flame.fill")
                    .foregroundStyle(DS.Colors.accentStreak)
            } compactTrailing: {
                CountdownText(state: context.state)
                    .font(DS.Typography.caption)
                    .foregroundStyle(phaseTint(context.state.phase))
                    .monospacedDigit()
                    .frame(maxWidth: 44)
            } minimal: {
                Image(systemName: "timer")
                    .foregroundStyle(DS.Colors.brandGreen)
            }
            .keylineTint(DS.Colors.brandGreen)
        }
    }
}

/// Lock Screen / banner presentation.
private struct FocusLockScreenView: View {
    let context: ActivityViewContext<FocusActivityAttributes>

    var body: some View {
        HStack(spacing: DS.Spacing.md) {
            MascotStamp(state: context.state)
                .frame(width: 52, height: 52)
            VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
                Text(phaseTitleKey(context.state.phase))
                    .font(DS.Typography.caption)
                    .foregroundStyle(DS.Colors.textSecondary)
                CountdownText(state: context.state)
                    .font(DS.Typography.title)
                    .foregroundStyle(phaseTint(context.state.phase))
                    .monospacedDigit()
                if let subject = context.attributes.subject {
                    Text(verbatim: subject)
                        .font(DS.Typography.caption)
                        .foregroundStyle(DS.Colors.textSecondary)
                }
            }
            Spacer()
            StreakStamp(count: context.attributes.streakCount)
        }
        .padding(DS.Spacing.md)
    }
}

/// Static frog frame (Live Activity renders are snapshots, so the
/// expressive `staticPose` is exactly right).
private struct MascotStamp: View {
    let state: FocusActivityAttributes.ContentState

    var body: some View {
        let mascotState: MascotState = state.isPaused ? .idle : .studying
        Canvas { canvasContext, size in
            FrogRenderer.draw(
                pose: MascotAnimator.staticPose(for: mascotState),
                in: canvasContext,
                size: size
            )
        }
        .accessibilityLabel(Text(mascotState.accessibilityLabelKey))
    }
}

private struct StreakStamp: View {
    let count: Int

    var body: some View {
        HStack(spacing: DS.Spacing.xxs) {
            Image(systemName: "flame.fill")
                .foregroundStyle(DS.Colors.accentStreak)
            Text(verbatim: "\(count)")
                .font(DS.Typography.headline)
                .foregroundStyle(DS.Colors.textPrimary)
                .monospacedDigit()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("streak.a11y \(count)"))
    }
}

/// Frozen text while paused; otherwise a system-animated countdown.
private struct CountdownText: View {
    let state: FocusActivityAttributes.ContentState

    var body: some View {
        if state.isPaused {
            let seconds = Int((state.pausedRemaining ?? 0).rounded())
            Text(verbatim: String(format: "%02d:%02d", seconds / 60, seconds % 60))
        } else {
            Text(timerInterval: Date.now...max(Date.now, state.endDate), countsDown: true)
        }
    }
}

private func phaseTitleKey(_ phase: String) -> LocalizedStringKey {
    switch phase {
    case "shortBreak": "la.phase.shortBreak"
    case "longBreak": "la.phase.longBreak"
    default: "la.phase.focus"
    }
}

private func phaseTint(_ phase: String) -> Color {
    phase == "focus" ? DS.Colors.brandGreen : DS.Colors.accentFocus
}
