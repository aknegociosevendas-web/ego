# Mascot Animation Reference (for the SwiftUI port)

The frog mascot (F-13) was prototyped in `frog-prototype.html` (open it in a browser to see the
motion). This file tells the coding agent how to reproduce it natively in SwiftUI. **Match the
stakeholder's reference image for final art**; use this only for the animation system + palette.

## Concept
Olive-green frog, **side profile** facing right, wide low body, single big eye (+ small far eye),
wide mouth, wearing a **floppy brown explorer hat** with a jagged crown. Style = "Claude companion"
chibi pixel-art, crisp pixels (nearest-neighbor, no smoothing).

## Rendering approach (procedural, no external sprite files needed for v1)
- Draw on a **low logical grid (~72×72)** and scale up with **`.interpolation(.none)`** in a
  SwiftUI `Canvas` (integer scale, e.g. 5×). Keeps pixels crisp.
- Frog is drawn from parts (body, belly, eyes, mouth, front foot, hat, book) in **local coords**
  with the feet at the origin; up is negative Y.
- Animate by transforming a single **`FrogPose`** struct per frame — this is what gives the fluid
  squash & stretch feel. No huge sprite sheets required for the core states.

## FrogPose (suggested Swift struct)
```
struct FrogPose {
    var jump: CGFloat = 0        // vertical offset up (px, logical)
    var offsetX: CGFloat = 0     // horizontal (hops)
    var scaleX: CGFloat = 1      // squash/stretch (anchored at feet)
    var scaleY: CGFloat = 1
    var headBob: CGFloat = 0     // nods head/eyes/hat/mouth together
    var eye: EyeMode = .open     // .open / .blink / .sleep / .happy
    var lookX: CGFloat = 0       // pupil offset
    var lookY: CGFloat = 0
    var mouth: MouthMode = .smile // .smile / .open / .sleep / .study
    var armRaise: CGFloat = 0    // 0 = foot down, 1 = front foot up
    var blush = true
    var hat = true
    var book = false
    var sparks = false
    var alpha: CGFloat = 1
}
```

## States (drive an enum → pose each frame)
| State | Behavior |
|-------|----------|
| `idle` | slow breathe (scaleY ±0.035, inverse scaleX), tiny headBob, blink ~every 3.1s, pupils drift slightly |
| `hop` (forward) | 4 hops moving right: crouch (squashY) → launch (arc `sin(π·p)`, stretchY) → land (squashY); mouth opens mid-air; loops with a short fade (`alpha`) on reset |
| `sleep` | eyes closed line, mouth tiny, slow deep breathing, spawn **"Z" particles** rising from the snout and fading |
| `study` | `book = true` in front, head bobs (reading), eyes look down + scan (lookX oscillates), occasional blink |
| `happy` (up) | repeated vertical jumps (`sin`), strong squash on land / stretch mid-air, **front foot up** (armRaise=1), open mouth, `sparks` at apex |

Extra states already specced in `docs/05-MASCOT.md`: `celebrating`, `worried`, `guarding` (Focus
Mode shield), `levelUp`. Wire them from app events per the golden rule ("mascot reacts to events").

## Timing constants (from the prototype — tune freely)
- Hop: 0.6s per hop, 4 hops, ~0.55s pause + fade before loop.
- Happy jump: 0.52s cycle, apex ~15px.
- Blink: ~0.13s, every ~3s.
- Z spawn: every 0.75s while sleeping; rise ~0.28px/frame, fade over ~2.6s.

## Palette (matches locked design tokens where relevant)
```
outline   #183619
green      #6B8F3C   green light #88A94E   green dark #49661F
belly      #AEC473   belly dark  #93AA5C   spots      #3C5320
eye white  #F3F7E8   pupil       #152012   blush      #E58A86
hat        #7C4A26   hat dark    #573216   hat light  #9C6538
book       #B8463A   book page   #F2EAD2
spark      #F5A524 (amber accent) · Z tint #8FB0C9
```

## Accessibility
- Honor **Reduce Motion**: hold a single expressive frame per state instead of looping.
- Mascot is decorative → provide a concise `accessibilityLabel` (e.g. "Sapo do EGO, estudando").

## Notes
- Start fully procedural (above). Add hand-drawn sprite sheets later only for evolution tiers/skins.
- The prototype's draw order and part functions map 1:1 to SwiftUI `Canvas` draw calls.
