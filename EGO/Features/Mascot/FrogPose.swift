import Foundation

/// One frame of the frog, animated by transforming this struct over time
/// (assets/mascot/MASCOT-ANIMATION-REFERENCE.md). All units are logical
/// pixels on the 72×72 grid; the feet sit at the origin, up is negative Y.
struct FrogPose: Equatable {
    enum EyeMode: Equatable {
        case open, blink, happy
    }

    enum MouthMode: Equatable {
        case smile, open, study, frown
    }

    /// Vertical offset up from the baseline (jumps).
    var jump: CGFloat = 0
    /// Horizontal offset (hops).
    var offsetX: CGFloat = 0
    /// Squash & stretch, anchored at the feet.
    var scaleX: CGFloat = 1
    var scaleY: CGFloat = 1
    /// Nods head, eyes, hat and mouth together (positive = down).
    var headBob: CGFloat = 0
    var eye: EyeMode = .open
    /// Pupil offset.
    var lookX: CGFloat = 0
    var lookY: CGFloat = 0
    var mouth: MouthMode = .smile
    /// 0 = front foot down, 1 = raised (cheering).
    var armRaise: CGFloat = 0
    var blush = true
    var hat = true
    var book = false
    var sparks = false
    /// 0…1 progress of a falling tear (sad state); nil hides it.
    var tearPhase: CGFloat?
    /// 0…1 amber halo behind the frog (levelUp state).
    var glow: CGFloat = 0
    var alpha: CGFloat = 1
}
