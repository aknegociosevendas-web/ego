import SwiftUI

/// SwiftUI host for the pixel-art frog (F-13). Dumb view: receives a state,
/// renders the matching sprite frame. `idle` animates an 8-frame bob; other
/// states (and Reduce Motion) hold the resting frame. `.interpolation(.none)`
/// keeps the pixels crisp when scaled up.
struct MascotView: View {
    let state: MascotState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if reduceMotion || state != .idle {
                sprite(MascotSprite.restingImageName)
            } else {
                TimelineView(.periodic(from: .now, by: MascotSprite.idleFrameDuration)) { timeline in
                    sprite(MascotSprite.imageName(for: state, at: timeline.date))
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityLabel(Text(state.accessibilityLabelKey))
    }

    private func sprite(_ name: String) -> some View {
        Image(name)
            .resizable()
            .interpolation(.none)
            .aspectRatio(contentMode: .fit)
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
