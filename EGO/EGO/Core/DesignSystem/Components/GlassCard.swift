import SwiftUI

/// Translucent surface for content floating over an illustrated scene (the
/// immersive redesign). Blur + hairline border, so the scene reads through it.
struct GlassCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(DS.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DS.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.card)
                    .strokeBorder(DS.Colors.borderSubtle.opacity(0.6), lineWidth: 1)
            )
    }
}

#Preview {
    GlassCard {
        Text(verbatim: "Glass")
            .font(DS.Typography.body)
            .foregroundStyle(DS.Colors.textPrimary)
    }
    .padding(DS.Spacing.screenPadding)
    .background(DS.Colors.bgCanvas)
}
