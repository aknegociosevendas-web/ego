import SwiftUI

/// Notion-style surface: soft background, 16pt radius, hairline border.
/// Separation comes from the border, not shadows (docs/04 §5).
struct Card<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(DS.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DS.Colors.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.card)
                    .strokeBorder(DS.Colors.borderSubtle, lineWidth: 1)
            )
    }
}

#Preview {
    Card {
        Text(verbatim: "Card")
            .font(DS.Typography.body)
            .foregroundStyle(DS.Colors.textPrimary)
    }
    .padding(DS.Spacing.screenPadding)
    .background(DS.Colors.bgCanvas)
}
