import SwiftUI

/// The single freshest unlock of a completed session, in priority order —
/// level up, streak milestone (earned a freeze), completed goal. Nothing
/// new → the summary renders no card.
struct SummaryReward {
    let iconSystemName: String
    let title: Text

    /// Built from the session result the VM already produces (F-14).
    static func from(_ result: SessionCompletionService.Result) -> SummaryReward? {
        if result.didLevelUp {
            return SummaryReward(
                iconSystemName: "arrow.up.circle.fill",
                title: Text("summary.reward.levelUp \(result.newLevel)")
            )
        }
        if result.freezesEarned > 0 {
            return SummaryReward(
                iconSystemName: "snowflake",
                title: Text("summary.reward.milestone \(result.streakCurrent)")
            )
        }
        if result.goalsCompleted > 0 {
            return SummaryReward(
                iconSystemName: "target",
                title: Text("summary.reward.goal")
            )
        }
        return nil
    }
}

/// Horizontal glass card for a freshly unlocked reward on the session summary
/// (slice 5, journal redesign): icon | title + date | share.
struct SummaryRewardCard: View {
    let reward: SummaryReward
    /// Rendered story-card image shared as-is (placeholder until F-12).
    var shareImage: Image?

    var body: some View {
        HStack(spacing: DS.Spacing.sm) {
            Image(systemName: reward.iconSystemName)
                .font(DS.Typography.headline)
                .foregroundStyle(DS.Colors.brandGreen)
                .frame(width: 44, height: 44)
                .background(DS.Colors.bgSurface.opacity(0.55), in: Circle())

            VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
                reward.title
                    .font(DS.Typography.callout)
                    .foregroundStyle(DS.Colors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(verbatim: Date.now.formatted(date: .numeric, time: .omitted))
                    .font(DS.Typography.caption)
                    .foregroundStyle(DS.Colors.textSecondary)
            }

            Spacer(minLength: DS.Spacing.sm)

            if let shareImage {
                ShareLink(
                    item: shareImage,
                    preview: SharePreview(Text("summary.share"), image: shareImage)
                ) {
                    Text("summary.share")
                        .font(DS.Typography.caption)
                        .foregroundStyle(DS.Colors.textPrimary)
                        .padding(.horizontal, DS.Spacing.sm)
                        .padding(.vertical, DS.Spacing.xs)
                        .background(DS.Colors.bgSurface.opacity(0.55), in: Capsule())
                        .overlay(Capsule().strokeBorder(DS.Colors.borderSubtle, lineWidth: 1))
                }
            }
        }
        .padding(DS.Spacing.sm)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DS.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .strokeBorder(DS.Colors.borderSubtle.opacity(0.6), lineWidth: 1)
        )
    }
}

#Preview {
    VStack(spacing: DS.Spacing.sm) {
        SummaryRewardCard(
            reward: SummaryReward(
                iconSystemName: "arrow.up.circle.fill",
                title: Text(verbatim: "Nível 3 desbloqueado!")
            )
        )
        SummaryRewardCard(
            reward: SummaryReward(
                iconSystemName: "snowflake",
                title: Text(verbatim: "7 dias de sequência — freeze ganho!")
            )
        )
    }
    .padding(DS.Spacing.screenPadding)
    .background(DS.Colors.bgCanvas)
}
