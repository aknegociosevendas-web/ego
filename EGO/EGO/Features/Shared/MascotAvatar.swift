import SwiftUI

/// Small circular frog avatar with a level badge, for the top-right of the
/// immersive screens. Static resting frame (decorative, cheap).
struct MascotAvatar: View {
    let level: Int
    var diameter: CGFloat = 40

    var body: some View {
        Image(MascotSprite.restingImageName)
            .resizable()
            .interpolation(.none)
            .aspectRatio(contentMode: .fit)
            .padding(4)
            .frame(width: diameter, height: diameter)
            .background(DS.Colors.bgSurface, in: Circle())
            .overlay(Circle().strokeBorder(DS.Colors.borderSubtle, lineWidth: 1))
            .overlay(alignment: .bottomTrailing) {
                Text(verbatim: "\(level)")
                    .font(DS.Typography.caption)
                    .foregroundStyle(DS.Colors.textOnBrand)
                    .monospacedDigit()
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(DS.Colors.brandGreen, in: Capsule())
                    .overlay(Capsule().strokeBorder(DS.Colors.bgCanvas, lineWidth: 1.5))
                    .offset(x: 4, y: 4)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("profile.level \(level)"))
    }
}

#Preview {
    MascotAvatar(level: 7)
        .padding(DS.Spacing.screenPadding)
        .background(DS.Colors.bgCanvas)
}
