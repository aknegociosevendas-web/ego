import SwiftUI

/// Flame + day count (docs/04 §6). Uses the amber streak accent.
struct StreakBadge: View {
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
        .padding(.horizontal, DS.Spacing.sm)
        .padding(.vertical, DS.Spacing.xs)
        .background(DS.Colors.bgSurface)
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(DS.Colors.borderSubtle, lineWidth: 1))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("streak.a11y \(count)"))
    }
}

#Preview {
    StreakBadge(count: 12)
        .padding(DS.Spacing.screenPadding)
        .background(DS.Colors.bgCanvas)
}
