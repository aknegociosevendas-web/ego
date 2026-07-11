import SwiftUI

/// Draws the frog procedurally on a 72×72 logical grid (side profile facing
/// right), one `FrogPose` per frame. Parts are pixel-row rects so the
/// silhouette keeps a chunky pixel-art stepping at any scale.
enum FrogRenderer {
    static let gridSize: CGFloat = 72

    /// Body silhouette: half-width per 2px row, top (y = -28) to feet (y = 0).
    private static let bodyProfile: [CGFloat] = [6, 9, 12, 14, 15, 17, 18, 19, 19, 20, 20, 21, 21, 21]

    static func draw(pose: FrogPose, in context: GraphicsContext, size: CGSize) {
        var ctx = context
        let scale = min(size.width, size.height) / gridSize
        ctx.scaleBy(x: scale, y: scale)
        ctx.opacity = pose.alpha

        drawShadow(pose, &ctx)

        // Frog space: origin at the feet so squash/stretch anchors there.
        ctx.translateBy(x: gridSize / 2 + pose.offsetX, y: 62 - pose.jump)
        ctx.scaleBy(x: pose.scaleX, y: pose.scaleY)

        if pose.glow > 0 { drawGlow(pose.glow, &ctx) }
        drawBody(&ctx)
        drawBelly(&ctx)
        drawFarFoot(&ctx)
        drawFace(pose, &ctx)
        if pose.hat { drawHat(pose, &ctx) }
        if pose.book { drawBook(&ctx) }
        drawFrontFoot(pose, &ctx)
        if pose.sparks { drawSparks(&ctx) }
        if let tear = pose.tearPhase { drawTear(tear, pose, &ctx) }
    }

    // MARK: - Primitives

    private static func fill(
        _ ctx: inout GraphicsContext,
        _ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat,
        _ color: Color
    ) {
        ctx.fill(Path(CGRect(x: x, y: y, width: w, height: h)), with: .color(color))
    }

    /// Pixel-stepped disc from 1px rows.
    private static func disc(
        _ ctx: inout GraphicsContext,
        cx: CGFloat, cy: CGFloat, r: CGFloat,
        _ color: Color
    ) {
        var y = -r
        while y < r {
            let hw = (r * r - (y + 0.5) * (y + 0.5)).squareRoot().rounded(.down)
            if hw > 0 {
                fill(&ctx, cx - hw, cy + y, hw * 2, 1, color)
            }
            y += 1
        }
    }

    // MARK: - Parts (local coords, feet at origin, up = negative Y)

    private static func drawShadow(_ pose: FrogPose, _ ctx: inout GraphicsContext) {
        let halfWidth = 17 * max(0.55, 1 - pose.jump / 45)
        let rect = CGRect(
            x: gridSize / 2 - halfWidth + pose.offsetX,
            y: 63,
            width: halfWidth * 2,
            height: 4
        )
        ctx.fill(Path(ellipseIn: rect), with: .color(FrogPalette.outline.opacity(0.12)))
    }

    /// Level-up halo: concentric amber discs behind the frog (docs/05 §3
    /// "glow + evolve flash"). Uses the streak accent token.
    private static func drawGlow(_ intensity: CGFloat, _ ctx: inout GraphicsContext) {
        disc(&ctx, cx: 0, cy: -20, r: 32, FrogPalette.spark.opacity(0.10 * intensity))
        disc(&ctx, cx: 0, cy: -20, r: 25, FrogPalette.spark.opacity(0.14 * intensity))
    }

    private static func drawBody(_ ctx: inout GraphicsContext) {
        for (row, halfWidth) in bodyProfile.enumerated() {
            let y = CGFloat(-28 + 2 * row)
            fill(&ctx, -halfWidth, y, halfWidth * 2, 2, FrogPalette.outline)
        }
        for (row, halfWidth) in bodyProfile.enumerated() where row >= 1 {
            let y = CGFloat(-28 + 2 * row)
            fill(&ctx, -(halfWidth - 2), y, (halfWidth - 2) * 2, 2, FrogPalette.green)
        }
        // Top highlight + darker back rim + spots.
        for row in 1...2 {
            let halfWidth = bodyProfile[row] - 4
            fill(&ctx, -halfWidth, CGFloat(-28 + 2 * row), halfWidth * 2, 2, FrogPalette.greenLight)
        }
        for row in 4...12 {
            let halfWidth = bodyProfile[row]
            fill(&ctx, -(halfWidth - 2), CGFloat(-28 + 2 * row), 3, 2, FrogPalette.greenDark)
        }
        fill(&ctx, -10, -22, 2, 2, FrogPalette.spots)
        fill(&ctx, -15, -14, 2, 2, FrogPalette.spots)
        fill(&ctx, -5, -25, 2, 2, FrogPalette.spots)
    }

    private static func drawBelly(_ ctx: inout GraphicsContext) {
        for row in 9...13 {
            let y = CGFloat(-28 + 2 * row)
            let edge = bodyProfile[row] - 2
            let color = row == 9 ? FrogPalette.bellyDark : FrogPalette.belly
            fill(&ctx, 5, y, edge - 5, 2, color)
        }
    }

    private static func drawFarFoot(_ ctx: inout GraphicsContext) {
        fill(&ctx, -17, -4, 11, 4, FrogPalette.outline)
        fill(&ctx, -16, -3, 9, 3, FrogPalette.greenDark)
    }

    private static func drawFace(_ pose: FrogPose, _ ctx: inout GraphicsContext) {
        let bob = pose.headBob
        let lookX = min(2, max(-2, pose.lookX))
        let lookY = min(2.5, max(-2, pose.lookY))

        // Far eye bump (behind, smaller).
        disc(&ctx, cx: 0, cy: -29 + bob, r: 4, FrogPalette.outline)
        switch pose.eye {
        case .open:
            disc(&ctx, cx: 0, cy: -29 + bob, r: 2.5, FrogPalette.eyeWhite)
            fill(&ctx, -1 + lookX * 0.5, -30 + bob + lookY * 0.5, 2, 2, FrogPalette.pupil)
        case .blink, .happy:
            disc(&ctx, cx: 0, cy: -29 + bob, r: 2.5, FrogPalette.green)
            fill(&ctx, -2, -29.5 + bob, 5, 1.5, FrogPalette.outline)
        }

        // Near eye bump (front, big).
        disc(&ctx, cx: 11, cy: -27 + bob, r: 6, FrogPalette.outline)
        switch pose.eye {
        case .open:
            disc(&ctx, cx: 11, cy: -27 + bob, r: 4.5, FrogPalette.eyeWhite)
            fill(&ctx, 10.5 + lookX, -28.5 + bob + lookY, 3, 3, FrogPalette.pupil)
        case .blink:
            disc(&ctx, cx: 11, cy: -27 + bob, r: 4.5, FrogPalette.green)
            fill(&ctx, 7, -27.5 + bob, 8, 1.5, FrogPalette.outline)
        case .happy:
            disc(&ctx, cx: 11, cy: -27 + bob, r: 4.5, FrogPalette.eyeWhite)
            // "^" arch.
            fill(&ctx, 7, -25.5 + bob, 2, 2, FrogPalette.pupil)
            fill(&ctx, 9, -27.5 + bob, 4, 2, FrogPalette.pupil)
            fill(&ctx, 13, -25.5 + bob, 2, 2, FrogPalette.pupil)
        }

        // Mouth (kept above the belly patch, which starts at y = -10).
        switch pose.mouth {
        case .smile:
            fill(&ctx, 5, -13 + bob, 12, 2, FrogPalette.outline)
            fill(&ctx, 17, -15 + bob, 2, 2, FrogPalette.outline)
        case .open:
            fill(&ctx, 7, -16 + bob, 9, 6, FrogPalette.outline)
        case .study:
            fill(&ctx, 6, -13 + bob, 9, 2, FrogPalette.outline)
        case .frown:
            fill(&ctx, 5, -12 + bob, 11, 2, FrogPalette.outline)
            fill(&ctx, 16, -11 + bob, 2, 2, FrogPalette.outline)
        }

        if pose.blush {
            fill(&ctx, 14, -18 + bob, 4, 2, FrogPalette.blush)
        }
    }

    private static func drawHat(_ pose: FrogPose, _ ctx: inout GraphicsContext) {
        let bob = pose.headBob
        // Floppy brim (front longer, drooping tips).
        fill(&ctx, -15, -35 + bob, 34, 3, FrogPalette.hat)
        fill(&ctx, -15, -33 + bob, 34, 1, FrogPalette.hatDark)
        fill(&ctx, -17, -34 + bob, 2, 3, FrogPalette.hat)
        fill(&ctx, 19, -34 + bob, 2, 3, FrogPalette.hat)
        // Crown with a jagged top.
        fill(&ctx, -9, -37 + bob, 22, 2, FrogPalette.hat)
        fill(&ctx, -7, -39 + bob, 18, 2, FrogPalette.hat)
        fill(&ctx, -5, -41 + bob, 14, 2, FrogPalette.hat)
        fill(&ctx, 5, -41 + bob, 4, 2, FrogPalette.hatLight)
        fill(&ctx, -4, -43 + bob, 3, 2, FrogPalette.hat)
        fill(&ctx, 1, -43 + bob, 3, 2, FrogPalette.hat)
        fill(&ctx, 6, -43 + bob, 3, 2, FrogPalette.hat)
        // Band.
        fill(&ctx, -9, -36 + bob, 22, 1, FrogPalette.hatDark)
    }

    private static func drawBook(_ ctx: inout GraphicsContext) {
        fill(&ctx, 17.5, -14.5, 17, 10, FrogPalette.outline)
        fill(&ctx, 18, -14, 16, 9, FrogPalette.book)
        fill(&ctx, 19, -13, 6.5, 7, FrogPalette.bookPage)
        fill(&ctx, 26.5, -13, 6.5, 7, FrogPalette.bookPage)
        fill(&ctx, 25.5, -13, 1, 7, FrogPalette.book)
    }

    private static func drawFrontFoot(_ pose: FrogPose, _ ctx: inout GraphicsContext) {
        let lift = 10 * pose.armRaise
        let dx = 2 * pose.armRaise
        fill(&ctx, 6 + dx, -4 - lift, 12, 4, FrogPalette.outline)
        fill(&ctx, 7 + dx, -3 - lift, 10, 3, FrogPalette.green)
        fill(&ctx, 10 + dx, -1 - lift, 1, 1, FrogPalette.outline)
        fill(&ctx, 13 + dx, -1 - lift, 1, 1, FrogPalette.outline)
    }

    private static func drawSparks(_ ctx: inout GraphicsContext) {
        let positions: [(CGFloat, CGFloat)] = [(-18, -42), (24, -46), (3, -54), (27, -30)]
        for (x, y) in positions {
            fill(&ctx, x - 2, y - 0.75, 5, 1.5, FrogPalette.spark)
            fill(&ctx, x - 0.25, y - 2.5, 1.5, 5, FrogPalette.spark)
        }
    }

    private static func drawTear(_ phase: CGFloat, _ pose: FrogPose, _ ctx: inout GraphicsContext) {
        let drop = phase * 12
        let alpha = max(0, 1 - phase * 0.7)
        fill(&ctx, 16, -20 + pose.headBob + drop, 2, 3, FrogPalette.tear.opacity(alpha))
    }
}
