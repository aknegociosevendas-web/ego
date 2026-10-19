import SwiftUI
import UIKit

/// Layered forest-at-night scene behind the immersive Home (and the paywall
/// hero). Built in SwiftUI now; every layer first looks for a pixel-art PNG in
/// the asset catalog (`SceneSky`, `SceneTreesFar`, …) and falls back to the
/// procedural version, so real art can drop in later without code changes.
/// (The focus flow uses `AnimatedSceneView` frames since slice 5.)
struct ForestSceneView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Illustration-only shades (kept named here, not raw hex in view bodies).
    private enum Palette {
        static let skyTop = Color(red: 0x0E / 255, green: 0x1A / 255, blue: 0x0E / 255)
        static let skyBottom = Color(red: 0x1A / 255, green: 0x2E / 255, blue: 0x22 / 255)
        static let treesFar = Color(red: 0x16 / 255, green: 0x28 / 255, blue: 0x1B / 255)
        static let treesMid = Color(red: 0x1E / 255, green: 0x30 / 255, blue: 0x20 / 255)
        static let ground = Color(red: 0x12 / 255, green: 0x20 / 255, blue: 0x10 / 255)
        static let rock = Color(red: 0x2A / 255, green: 0x3A / 255, blue: 0x2E / 255)
        static let moon = Color(red: 0xE8 / 255, green: 0xED / 255, blue: 0xD8 / 255)
        static let star = Color.white
        static let firefly = Color(red: 0x8F / 255, green: 0xE0 / 255, blue: 0x90 / 255)
        static let reflection = Color(red: 0x2F / 255, green: 0xA5 / 255, blue: 0xA5 / 255)
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                sky(w: w, h: h)
                stars(w: w, h: h)
                moon(w: w, h: h)
                treesFar(w: w, h: h)
                treesMid(w: w, h: h)
                lake(w: w, h: h)
                foreground(w: w, h: h)
                fireflies(w: w, h: h)
            }
            .frame(width: w, height: h)
            .clipped()
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    // MARK: - Layer seam (PNG if present, else procedural)

    @ViewBuilder
    private func layer(_ assetName: String, @ViewBuilder fallback: () -> some View) -> some View {
        if UIImage(named: assetName) != nil {
            Image(assetName)
                .resizable()
                .interpolation(.none)
                .aspectRatio(contentMode: .fill)
        } else {
            fallback()
        }
    }

    // MARK: - Layers

    private func sky(w: CGFloat, h: CGFloat) -> some View {
        layer("SceneSky") {
            LinearGradient(
                colors: [Palette.skyTop, Palette.skyBottom],
                startPoint: .top, endPoint: .bottom
            )
        }
    }

    private func stars(w: CGFloat, h: CGFloat) -> some View {
        layer("SceneStars") {
            TimelineView(.animation(minimumInterval: 0.6, paused: reduceMotion)) { timeline in
                Canvas { ctx, _ in
                    let t = timeline.date.timeIntervalSinceReferenceDate
                    for star in Self.starField {
                        let base = 0.35 + 0.5 * star.brightness
                        let twinkle = reduceMotion ? base
                            : base * (0.65 + 0.35 * sin(t * 1.4 + star.phase))
                        let p = CGRect(
                            x: star.x * w, y: star.y * h * 0.62,
                            width: star.size, height: star.size
                        )
                        ctx.fill(Path(ellipseIn: p), with: .color(Palette.star.opacity(twinkle)))
                    }
                }
            }
        }
    }

    private func moon(w: CGFloat, h: CGFloat) -> some View {
        let d = w * 0.16
        // Kept center-left, clear of the top-right streak/avatar badges.
        return Circle()
            .fill(Palette.moon.opacity(0.9))
            .frame(width: d, height: d)
            .blur(radius: 0.5)
            .overlay(Circle().fill(Palette.moon).frame(width: d, height: d).opacity(0.15).blur(radius: 12))
            .position(x: w * 0.28, y: h * 0.14)
    }

    private func treesFar(w: CGFloat, h: CGFloat) -> some View {
        layer("SceneTreesFar") {
            Treeline(count: 9, jitter: 0.35)
                .fill(Palette.treesFar)
                .frame(height: h * 0.28)
                .frame(maxHeight: .infinity, alignment: .center)
                .offset(y: -h * 0.06)
        }
    }

    private func treesMid(w: CGFloat, h: CGFloat) -> some View {
        layer("SceneTreesMid") {
            Treeline(count: 6, jitter: 0.5)
                .fill(Palette.treesMid)
                .frame(height: h * 0.34)
                .frame(maxHeight: .infinity, alignment: .center)
                .offset(y: h * 0.02)
        }
    }

    private func lake(w: CGFloat, h: CGFloat) -> some View {
        layer("SceneLake") {
            LinearGradient(
                colors: [Palette.treesMid, Palette.ground],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: h * 0.22)
            .overlay(
                Ellipse()
                    .fill(Palette.reflection.opacity(0.18))
                    .frame(width: w * 0.22, height: h * 0.05)
                    .blur(radius: 6)
                    .offset(x: w * 0.28)
            )
            .frame(maxHeight: .infinity, alignment: .bottom)
            .offset(y: -h * 0.18)
        }
    }

    private func foreground(w: CGFloat, h: CGFloat) -> some View {
        layer("SceneForeground") {
            ZStack(alignment: .bottom) {
                // Ground band.
                Rectangle()
                    .fill(Palette.ground)
                    .frame(height: h * 0.24)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                // Rock the frog sits on (centered), roughly under the frog in
                // HomeView's layout flow.
                Ellipse()
                    .fill(Palette.rock)
                    .frame(width: w * 0.46, height: h * 0.09)
                    .overlay(
                        Ellipse().fill(Palette.ground.opacity(0.5))
                            .frame(width: w * 0.46, height: h * 0.09)
                            .offset(y: h * 0.03)
                    )
                    .position(x: w * 0.5, y: h * 0.56)
            }
        }
    }

    private func fireflies(w: CGFloat, h: CGFloat) -> some View {
        TimelineView(.animation(minimumInterval: 1 / 20, paused: reduceMotion)) { timeline in
            Canvas { ctx, _ in
                let t = timeline.date.timeIntervalSinceReferenceDate
                for fly in Self.fireflyField {
                    let drift = reduceMotion ? 0 : CGFloat(sin(t * fly.speed + fly.phase)) * 8
                    let glow = reduceMotion ? 0.5
                        : 0.35 + 0.4 * (0.5 + 0.5 * sin(t * 1.8 + fly.phase))
                    let p = CGRect(
                        x: fly.x * w + drift,
                        y: fly.y * h + CGFloat(cos(t * fly.speed * 0.7 + fly.phase)) * (reduceMotion ? 0 : 5),
                        width: 3, height: 3
                    )
                    ctx.fill(
                        Path(ellipseIn: p.insetBy(dx: -2, dy: -2)),
                        with: .color(Palette.firefly.opacity(glow * 0.35))
                    )
                    ctx.fill(Path(ellipseIn: p), with: .color(Palette.firefly.opacity(glow)))
                }
            }
        }
    }

    // MARK: - Deterministic fields

    private struct Star { let x, y, size, brightness, phase: CGFloat }
    private struct Firefly { let x, y, speed, phase: CGFloat }

    private static let starField: [Star] = (0..<46).map { i in
        let r = Double(i)
        return Star(
            x: CGFloat((sin(r * 12.9898) * 43758.5453).truncatingRemainder(dividingBy: 1).magnitude),
            y: CGFloat((sin(r * 78.233) * 12543.65).truncatingRemainder(dividingBy: 1).magnitude),
            size: CGFloat(1 + (i % 3)),
            brightness: CGFloat((sin(r * 3.1) * 0.5 + 0.5)),
            phase: CGFloat(r)
        )
    }

    private static let fireflyField: [Firefly] = (0..<7).map { i in
        let r = Double(i)
        return Firefly(
            x: CGFloat(0.12 + 0.76 * (sin(r * 91.17) * 0.5 + 0.5)),
            y: CGFloat(0.5 + 0.32 * (sin(r * 47.3) * 0.5 + 0.5)),
            speed: CGFloat(0.6 + 0.5 * (sin(r * 5.1) * 0.5 + 0.5)),
            phase: CGFloat(r * 1.7)
        )
    }
}

/// A jagged pine-silhouette baseline used for the treeline layers (and the
/// Study header banner).
struct Treeline: Shape {
    let count: Int
    let jitter: CGFloat

    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        let step = rect.width / CGFloat(count)
        for i in 0...count {
            let x = rect.minX + CGFloat(i) * step
            let peakSeed = (sin(Double(i) * 12.9898) * 43758.5453).truncatingRemainder(dividingBy: 1).magnitude
            let peakY = rect.minY + rect.height * (1 - jitter * CGFloat(peakSeed))
            if i > 0 {
                p.addLine(to: CGPoint(x: x - step / 2, y: peakY))
            }
            p.addLine(to: CGPoint(x: x, y: rect.maxY))
        }
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

#Preview {
    ForestSceneView()
}
