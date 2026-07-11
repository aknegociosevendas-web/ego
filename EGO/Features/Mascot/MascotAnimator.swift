import Foundation

/// State + time → `FrogPose`. Timing constants come from the HTML prototype
/// (assets/mascot/MASCOT-ANIMATION-REFERENCE.md); tune freely.
enum MascotAnimator {
    static func pose(for state: MascotState, at date: Date) -> FrogPose {
        let t = date.timeIntervalSinceReferenceDate
        switch state {
        case .idle: return idlePose(t)
        case .studying: return studyingPose(t)
        case .happy: return happyPose(t)
        case .sad: return sadPose(t)
        case .worried: return worriedPose(t)
        case .levelUp: return levelUpPose(t)
        case .guarding: return guardingPose(t)
        }
    }

    /// Reduce Motion: one expressive frame per state, no looping.
    static func staticPose(for state: MascotState) -> FrogPose {
        var pose = FrogPose()
        switch state {
        case .idle:
            break
        case .studying:
            pose.book = true
            pose.mouth = .study
            pose.lookY = 2
            pose.armRaise = 0.35
        case .happy:
            pose.eye = .happy
            pose.mouth = .open
            pose.armRaise = 1
            pose.sparks = true
        case .sad:
            pose.headBob = 3
            pose.mouth = .frown
            pose.lookY = 2
            pose.tearPhase = 0.5
        case .worried:
            pose.headBob = 1.5
            pose.mouth = .study
            pose.lookX = 2
        case .levelUp:
            pose.eye = .happy
            pose.mouth = .open
            pose.armRaise = 1
            pose.sparks = true
            pose.glow = 1
        case .guarding:
            pose.armRaise = 0.7
            pose.mouth = .study
            pose.blush = false
        }
        return pose
    }

    // MARK: - Per-state loops

    private static func idlePose(_ t: TimeInterval) -> FrogPose {
        var pose = FrogPose()
        let breathe = sin(t * 2 * .pi / 3.2)
        pose.scaleY = 1 + 0.035 * breathe
        pose.scaleX = 1 - 0.02 * breathe
        pose.headBob = 0.8 * sin(t * 2 * .pi / 3.2 + 0.4)
        pose.lookX = 1.2 * sin(t * 0.5)
        if isBlinking(t, every: 3.1) {
            pose.eye = .blink
        }
        return pose
    }

    private static func studyingPose(_ t: TimeInterval) -> FrogPose {
        var pose = FrogPose()
        pose.book = true
        pose.mouth = .study
        pose.armRaise = 0.35
        let breathe = sin(t * 2 * .pi / 3.6)
        pose.scaleY = 1 + 0.02 * breathe
        pose.headBob = 1.4 * sin(t * 2 * .pi / 1.8)
        pose.lookY = 2
        pose.lookX = 1.5 * sin(t * 2 * .pi / 2.6)
        if isBlinking(t, every: 4.0) {
            pose.eye = .blink
        }
        return pose
    }

    private static func happyPose(_ t: TimeInterval) -> FrogPose {
        var pose = FrogPose()
        let cycle: TimeInterval = 0.52
        let p = (t.truncatingRemainder(dividingBy: cycle)) / cycle
        let arc = sin(.pi * p)
        pose.jump = 15 * arc
        // Squash on the ground, stretch mid-air.
        pose.scaleY = 0.9 + 0.26 * arc
        pose.scaleX = 1.08 - 0.14 * arc
        pose.armRaise = 1
        pose.eye = .happy
        pose.mouth = .open
        pose.sparks = pose.jump > 11
        return pose
    }

    private static func sadPose(_ t: TimeInterval) -> FrogPose {
        var pose = FrogPose()
        pose.headBob = 3
        pose.scaleY = 0.97 + 0.015 * sin(t * 2 * .pi / 4)
        pose.mouth = .frown
        pose.lookY = 2.5
        pose.tearPhase = CGFloat((t.truncatingRemainder(dividingBy: 2.2)) / 2.2)
        if isBlinking(t, every: 5.0) {
            pose.eye = .blink
        }
        return pose
    }

    private static func worriedPose(_ t: TimeInterval) -> FrogPose {
        var pose = FrogPose()
        pose.mouth = .study
        // Nervous tremble + darting eyes ("looks at the clock").
        pose.offsetX = 0.6 * sin(t * 2 * .pi * 4)
        pose.headBob = 1 + 0.5 * sin(t * 2 * .pi * 2)
        pose.lookX = sin(t * 2 * .pi / 1.6) > 0 ? 2 : -2
        pose.lookY = 0.5
        pose.scaleY = 1 + 0.015 * sin(t * 2 * .pi / 1.2)
        if isBlinking(t, every: 2.2) {
            pose.eye = .blink
        }
        return pose
    }

    private static func levelUpPose(_ t: TimeInterval) -> FrogPose {
        var pose = FrogPose()
        // Evolve flash: pulsing glow + strong stretch bounces + sparks.
        let bounce = sin(t * 2 * .pi / 0.9)
        pose.glow = 0.7 + 0.3 * sin(t * 2 * .pi / 0.45)
        pose.jump = 6 + 4 * bounce
        pose.scaleY = 1.05 + 0.1 * bounce
        pose.scaleX = 1 - 0.06 * bounce
        pose.armRaise = 1
        pose.eye = .happy
        pose.mouth = .open
        pose.sparks = true
        return pose
    }

    private static func guardingPose(_ t: TimeInterval) -> FrogPose {
        var pose = FrogPose()
        // Arms-crossed "blocked" stance (docs/05 §3): planted, front foot up,
        // steady gaze, minimal breathing.
        pose.armRaise = 0.7
        pose.mouth = .study
        pose.blush = false
        pose.scaleY = 1 + 0.012 * sin(t * 2 * .pi / 4.2)
        pose.lookX = 0
        pose.lookY = 0.5
        if isBlinking(t, every: 4.6) {
            pose.eye = .blink
        }
        return pose
    }

    /// ~0.13s blink windows (prototype timing).
    private static func isBlinking(_ t: TimeInterval, every period: TimeInterval) -> Bool {
        t.truncatingRemainder(dividingBy: period) < 0.13
    }
}
