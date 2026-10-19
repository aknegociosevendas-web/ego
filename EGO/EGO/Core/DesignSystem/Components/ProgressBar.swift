import SwiftUI

/// Horizontal capsule progress (XP bar, goals, subject breakdown; docs/04 §6).
struct ProgressBar: View {
    /// 0…1.
    var progress: Double
    var tint: Color = DS.Colors.brandGreen
    var height: CGFloat = 8

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(DS.Colors.bgSurfaceAlt)
                Capsule()
                    .fill(tint)
                    .frame(width: geometry.size.width * max(0, min(1, progress)))
            }
        }
        .frame(height: height)
    }
}

#Preview {
    VStack(spacing: DS.Spacing.sm) {
        ProgressBar(progress: 0.4)
        ProgressBar(progress: 0.85, tint: DS.Colors.accentStreak)
    }
    .padding(DS.Spacing.screenPadding)
    .background(DS.Colors.bgCanvas)
}
