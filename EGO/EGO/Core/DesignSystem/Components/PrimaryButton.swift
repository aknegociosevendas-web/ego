import SwiftUI

/// Full-width brand-green action button (docs/04 §6).
struct PrimaryButton: View {
    let titleKey: LocalizedStringKey
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(titleKey)
                .font(DS.Typography.headline)
        }
        .buttonStyle(PrimaryButtonStyle())
    }
}

private struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(DS.Colors.textOnBrand)
            .frame(maxWidth: .infinity)
            .padding(.vertical, DS.Spacing.md)
            .background(DS.Colors.brandGreen.opacity(configuration.isPressed ? 0.85 : 1))
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.button))
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    PrimaryButton(titleKey: "onboarding.start") {}
        .padding(DS.Spacing.screenPadding)
        .background(DS.Colors.bgCanvas)
}
