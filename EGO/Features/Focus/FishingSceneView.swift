import SwiftUI
import UIKit

/// Full-screen focus scene (F-01 redesign): the explorer frog fishing at the
/// lake edge. Reuses `ForestSceneView` (sky, moon, treelines, lake, fireflies)
/// in the chosen scenery and layers a fishing rig. When the dedicated focus
/// sheet (`MascotFrogFocus0…7`, rod in frame) is in the catalog it animates
/// that; otherwise it falls back to the idle frog plus a drawn rod. Line and
/// bobber are always procedural, anchored to the rod tip.
/// All motion honors Reduce Motion (static frame + still bobber).
struct FishingSceneView: View {
    /// Slightly livelier "tugs" while the timer runs.
    var running: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Rig-only shades (named here, not raw hex in the drawing code).
    private enum Palette {
        static let rod = Color(red: 0x6D / 255, green: 0x3D / 255, blue: 0x08 / 255)
        static let line = Color.white.opacity(0.45)
        static let bobber = Color(red: 0xD1 / 255, green: 0x3B / 255, blue: 0x3B / 255)
        static let bobberCap = Color(red: 0xE8 / 255, green: 0xED / 255, blue: 0xD8 / 255)
        static let ripple = Color(red: 0x2F / 255, green: 0xA5 / 255, blue: 0xA5 / 255)
    }

    private var hasFocusSheet: Bool {
        UIImage(named: MascotSprite.focusRestingImageName) != nil
    }

    var body: some View {
        ForestSceneView()
            .overlay { rig }
            .ignoresSafeArea()
    }

    private var rig: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                if hasFocusSheet {
                    focusSprite(w: w, h: h)
                } else {
                    MascotView(state: .idle)
                        .frame(width: w * 0.40, height: w * 0.40)
                        .position(x: w * 0.44, y: h * 0.52)
                }

                TimelineView(.animation(minimumInterval: 1 / 20, paused: reduceMotion)) { timeline in
                    Canvas { ctx, _ in
                        draw(ctx, w: w, h: h, at: timeline.date)
                    }
                }
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    /// Focus-sheet frog (rod already in the art), pixel-crisp like MascotView.
    private func focusSprite(w: CGFloat, h: CGFloat) -> some View {
        Group {
            if reduceMotion {
                spriteImage(MascotSprite.focusRestingImageName)
            } else {
                TimelineView(.periodic(from: .now, by: MascotSprite.focusFrameDuration)) { timeline in
                    spriteImage(MascotSprite.focusImageName(at: timeline.date))
                }
            }
        }
        .frame(width: focusSpriteSize(w: w), height: focusSpriteSize(w: w))
        .position(focusSpriteCenter(w: w, h: h))
    }

    private func spriteImage(_ name: String) -> some View {
        Image(name)
            .resizable()
            .interpolation(.none)
            .aspectRatio(contentMode: .fit)
    }

    private func focusSpriteSize(w: CGFloat) -> CGFloat { w * 0.55 }

    private func focusSpriteCenter(w: CGFloat, h: CGFloat) -> CGPoint {
        CGPoint(x: w * 0.47, y: h * 0.50)
    }

    /// Where the fishing line starts. With the focus sheet, the rod is in the
    /// sprite and the tip sits at a fixed pixel anchor; procedurally, it's the
    /// drawn rod's tip (which dips with the tug).
    private func rodTip(w: CGFloat, h: CGFloat, tug: CGFloat) -> CGPoint {
        if hasFocusSheet {
            let size = focusSpriteSize(w: w)
            let center = focusSpriteCenter(w: w, h: h)
            return CGPoint(
                x: center.x + (MascotSprite.focusRodTipAnchor.x - 0.5) * size,
                y: center.y + (MascotSprite.focusRodTipAnchor.y - 0.5) * size
            )
        }
        return CGPoint(x: w * 0.72, y: h * 0.40 + tug * 12)
    }

    private func draw(_ ctx: GraphicsContext, w: CGFloat, h: CGFloat, at date: Date) {
        let t = date.timeIntervalSinceReferenceDate

        // Occasional "tug": a short bump near the end of each cycle.
        let cycle: TimeInterval = running ? 6.5 : 9.0
        let p = t.truncatingRemainder(dividingBy: cycle)
        let tug = (!reduceMotion && p > cycle - 0.5)
            ? CGFloat(sin((p - (cycle - 0.5)) / 0.5 * .pi))
            : 0
        let bob = reduceMotion ? 0 : CGFloat(sin(t * 1.6)) * 3

        let tip = rodTip(w: w, h: h, tug: tug)
        let bobberBase = CGPoint(x: w * 0.70, y: h * 0.63)
        let bobber = CGPoint(x: bobberBase.x, y: bobberBase.y + bob + tug * 16)

        // Rod — only when the frog art doesn't already include it.
        if !hasFocusSheet {
            var rod = Path()
            rod.move(to: CGPoint(x: w * 0.50, y: h * 0.50))
            rod.addLine(to: tip)
            ctx.stroke(rod, with: .color(Palette.rod), style: StrokeStyle(lineWidth: 4, lineCap: .round))
        }

        // Line (rod tip → bobber).
        var line = Path()
        line.move(to: tip)
        line.addLine(to: bobber)
        ctx.stroke(line, with: .color(Palette.line), lineWidth: 1)

        // Ripple rings where the line meets the water.
        let rippleSpread = 1 + (reduceMotion ? 0 : 0.3 * CGFloat(sin(t * 1.1)))
        for i in 1...2 {
            let rw = CGFloat(i) * 14 * rippleSpread
            let rh = rw * 0.4
            let rect = CGRect(x: bobber.x - rw / 2, y: bobber.y - rh / 2, width: rw, height: rh)
            ctx.stroke(
                Path(ellipseIn: rect),
                with: .color(Palette.ripple.opacity(0.28 / Double(i))),
                lineWidth: 1
            )
        }

        // Bobber (crisp little float).
        let r: CGFloat = 5
        ctx.fill(
            Path(ellipseIn: CGRect(x: bobber.x - r, y: bobber.y - r, width: r * 2, height: r * 2)),
            with: .color(Palette.bobber)
        )
        ctx.fill(
            Path(ellipseIn: CGRect(x: bobber.x - r, y: bobber.y - r, width: r * 2, height: r * 0.9)),
            with: .color(Palette.bobberCap)
        )
    }
}

#Preview {
    FishingSceneView(running: true)
}
