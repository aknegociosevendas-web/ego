import SwiftUI

/// Big number + caption on a card surface, for dashboards (docs/04 §6).
struct StatTile: View {
    /// Preformatted value (e.g. "2h 30min", "87%") — formatting is the caller's job.
    let value: String
    let labelKey: LocalizedStringKey

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
                Text(value)
                    .font(DS.Typography.title)
                    .foregroundStyle(DS.Colors.textPrimary)
                Text(labelKey)
                    .font(DS.Typography.caption)
                    .foregroundStyle(DS.Colors.textSecondary)
            }
        }
    }
}

#Preview {
    StatTile(value: "2h 30min", labelKey: "placeholder.comingSoon")
        .padding(DS.Spacing.screenPadding)
        .background(DS.Colors.bgCanvas)
}
