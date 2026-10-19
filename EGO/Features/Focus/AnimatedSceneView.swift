import SwiftUI

/// Full-screen illustrated focus scene: loops the 32-frame sequence of the
/// chosen scenery at its authored 8 fps (4s seamless loop). Frames are looked
/// up by name so UIKit's image cache decodes them on demand — never pre-load
/// the sequence into memory (~54 MB decoded per scenery; see asset README).
/// `.interpolation(.none)` keeps the pixel-style art crisp when scaled.
/// Static frame 00 when not animating or under Reduce Motion.
struct AnimatedSceneView: View {
    var scenery: FocusScenery
    /// Callers animate only while a session runs (setup/summary stay static).
    var animating: Bool = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if reduceMotion || !animating {
                frame(scenery.staticImageName)
            } else {
                TimelineView(.animation(minimumInterval: 1 / FocusScenery.frameRate)) { timeline in
                    frame(scenery.frameImageName(frameIndex(at: timeline.date)))
                }
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    private func frameIndex(at date: Date) -> Int {
        let step = Int(date.timeIntervalSinceReferenceDate * FocusScenery.frameRate)
        return ((step % FocusScenery.frameCount) + FocusScenery.frameCount) % FocusScenery.frameCount
    }

    private func frame(_ name: String) -> some View {
        GeometryReader { geo in
            Image(name)
                .resizable()
                .interpolation(.none)
                .aspectRatio(contentMode: .fill)
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
        }
        .ignoresSafeArea()
    }
}

#Preview("Dia") {
    AnimatedSceneView(scenery: .day)
}

#Preview("Noite") {
    AnimatedSceneView(scenery: .night)
}
