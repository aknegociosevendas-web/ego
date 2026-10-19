import Foundation

/// Sprite-sheet frame math for the frog mascot (F-13). The 8 idle frames live
/// in `Assets.xcassets/Mascot` as `MascotFrog0…7` (32×32, chroma-keyed to
/// transparent). Only `idle` animates for now — a gentle 8-frame bob whose
/// cadence follows `frog_anim.gif` (~7fps). Other states hold the resting
/// frame until they get dedicated sheets.
enum MascotSprite {
    static let frameCount = 8
    /// Per-frame hold for the idle bob (~7fps ≈ the reference GIF's pace).
    static let idleFrameDuration: TimeInterval = 0.14
    /// Resting frame shown for static states and Reduce Motion.
    static let restingImageName = "MascotFrog0"

    static func imageName(forFrame index: Int) -> String {
        "MascotFrog\(min(max(index, 0), frameCount - 1))"
    }

    /// Frame index for `state` at `date`. Non-idle states are static (frame 0).
    static func imageName(for state: MascotState, at date: Date) -> String {
        guard state == .idle else { return restingImageName }
        let step = Int(date.timeIntervalSinceReferenceDate / idleFrameDuration)
        return imageName(forFrame: ((step % frameCount) + frameCount) % frameCount)
    }

    // MARK: - Focus scene (fishing) sheet

    /// The focus-scene frog (fishing pose, rod in frame) is a second 8-frame
    /// sheet: `MascotFrogFocus0…7`, 64×64, transparent background, same ~7fps
    /// cadence. The rod tip must sit at pixel (56, 20) ±1 in every frame —
    /// `FishingSceneView` anchors the procedural line/bobber there. Until the
    /// frames land in the catalog, callers fall back to the idle sheet plus a
    /// procedurally drawn rod.
    static let focusFrameCount = 8
    static let focusFrameDuration: TimeInterval = 0.14
    /// Frame shown for Reduce Motion (and availability probing).
    static let focusRestingImageName = "MascotFrogFocus0"
    /// Rod-tip anchor inside the 64×64 focus frame, as a unit fraction of the
    /// canvas — the fishing line attaches here.
    static let focusRodTipAnchor = CGPoint(x: 56.0 / 64.0, y: 20.0 / 64.0)

    static func focusImageName(forFrame index: Int) -> String {
        "MascotFrogFocus\(min(max(index, 0), focusFrameCount - 1))"
    }

    static func focusImageName(at date: Date) -> String {
        let step = Int(date.timeIntervalSinceReferenceDate / focusFrameDuration)
        return focusImageName(forFrame: ((step % focusFrameCount) + focusFrameCount) % focusFrameCount)
    }
}
