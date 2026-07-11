import SwiftUI

/// SwiftUI host for the procedural frog (F-13). Dumb view: receives a state,
/// renders it. With Reduce Motion on, holds a static expressive frame.
struct MascotView: View {
    let state: MascotState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if reduceMotion {
                frame(for: MascotAnimator.staticPose(for: state))
            } else {
                TimelineView(.animation(minimumInterval: 1.0 / 24.0)) { timeline in
                    frame(for: MascotAnimator.pose(for: state, at: timeline.date))
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityLabel(Text(state.accessibilityLabelKey))
    }

    private func frame(for pose: FrogPose) -> some View {
        Canvas { context, size in
            FrogRenderer.draw(pose: pose, in: context, size: size)
        }
    }
}

#Preview("Estados") {
    VStack {
        HStack {
            MascotView(state: .idle)
            MascotView(state: .studying)
        }
        HStack {
            MascotView(state: .happy)
            MascotView(state: .sad)
        }
    }
    .padding(DS.Spacing.screenPadding)
    .background(DS.Colors.bgCanvas)
}
