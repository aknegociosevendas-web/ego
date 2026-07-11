import SwiftUI

/// Post-session feedback sheet: celebrating mascot + XP/coins earned +
/// streak outcome (F-14 feedback loop, docs/07 §1).
struct SessionSummaryView: View {
    let summary: CompletedSessionSummary
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: DS.Spacing.md) {
            MascotView(state: summary.result.didLevelUp ? .levelUp : .happy)
                .frame(width: 140, height: 140)

            Text("summary.title")
                .font(DS.Typography.title)
                .foregroundStyle(DS.Colors.textPrimary)

            Text("summary.minutes \(summary.minutes)")
                .font(DS.Typography.callout)
                .foregroundStyle(DS.Colors.textSecondary)

            HStack(spacing: DS.Spacing.sm) {
                StatTile(value: "+\(summary.result.xpEarned)", labelKey: "summary.xp")
                StatTile(value: "+\(summary.result.coinsEarned)", labelKey: "summary.coins")
            }

            if summary.result.didLevelUp {
                Text("summary.levelUp \(summary.result.newLevel)")
                    .font(DS.Typography.headline)
                    .foregroundStyle(DS.Colors.brandGreenDeep)
            }

            streakLine
                .font(DS.Typography.callout)
                .foregroundStyle(DS.Colors.textSecondary)
                .multilineTextAlignment(.center)

            if summary.result.freezesEarned > 0 {
                HStack(spacing: DS.Spacing.xxs) {
                    Image(systemName: "snowflake")
                        .foregroundStyle(DS.Colors.accentFocus)
                    Text("summary.freezeEarned")
                }
                .font(DS.Typography.callout)
                .foregroundStyle(DS.Colors.textSecondary)
            }

            if summary.result.goalsCompleted > 0 {
                HStack(spacing: DS.Spacing.xxs) {
                    Image(systemName: "target")
                        .foregroundStyle(DS.Colors.brandGreenDeep)
                    Text("summary.goalsCompleted \(summary.result.goalsCompleted)")
                }
                .font(DS.Typography.callout)
                .foregroundStyle(DS.Colors.textSecondary)
            }

            PrimaryButton(titleKey: "summary.continue") {
                dismiss()
            }
        }
        .padding(.horizontal, DS.Spacing.screenPadding)
        .padding(.vertical, DS.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DS.Colors.bgCanvas)
    }

    private var streakLine: some View {
        HStack(alignment: .firstTextBaseline, spacing: DS.Spacing.xxs) {
            Image(systemName: "flame.fill")
                .foregroundStyle(DS.Colors.accentStreak)
            streakText
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var streakText: Text {
        switch summary.result.streakOutcome {
        case .started:
            Text("summary.streak.started")
        case .extended:
            Text("summary.streak.extended \(summary.result.streakCurrent)")
        case .alreadyQualifiedToday:
            Text("summary.streak.already")
        case .extendedWithFreezes:
            Text("summary.streak.frozen")
        case .reset:
            Text("summary.streak.reset")
        }
    }
}

#Preview {
    SessionSummaryView(summary: CompletedSessionSummary(
        minutes: 25,
        result: SessionCompletionService.Result(
            xpEarned: 35,
            coinsEarned: 5,
            didLevelUp: true,
            newLevel: 2,
            streakOutcome: .extended,
            streakCurrent: 4,
            freezesEarned: 1,
            goalsCompleted: 1
        )
    ))
}
