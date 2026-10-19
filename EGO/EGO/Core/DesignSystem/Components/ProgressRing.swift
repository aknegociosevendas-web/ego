import SwiftUI

/// Circular progress for the Pomodoro (docs/04 §6).
struct ProgressRing: View {
    /// 0…1.
    var progress: Double
    var tint: Color = DS.Colors.brandGreen
    var lineWidth: CGFloat = 10

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Circle()
                .stroke(DS.Colors.bgSurfaceAlt, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0, min(1, progress)))
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? nil : .linear(duration: 0.25), value: progress)
        }
    }
}

#Preview {
    ProgressRing(progress: 0.65)
        .frame(width: 180, height: 180)
        .padding(DS.Spacing.screenPadding)
        .background(DS.Colors.bgCanvas)
}
