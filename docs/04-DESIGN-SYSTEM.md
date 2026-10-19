# 04 — Design System

> Direction: **Notion-like, light, minimal, calm.** Content-first, generous whitespace, soft
> surfaces, subtle depth. Playfulness comes from the pixel-art mascot and gamification, not from
> a loud UI. **Colors and fonts below are PLACEHOLDERS** — to be locked with the stakeholder.

## 1. Principles

1. **Calm & clear** — a study app must reduce cognitive load. Few colors, strong hierarchy.
2. **Notion-ish** — neutral canvas, light gray surfaces, rounded cards, understated borders.
3. **One accent** — a single brand accent for primary actions/streak; everything else neutral.
4. **Pixel-art as the personality** — the mascot and story cards carry the fun; UI stays clean.
5. **Accessible** — Dynamic Type, ≥4.5:1 contrast, VoiceOver labels, reduce-motion respected.

## 2. Color tokens (LOCKED v1 — green-based)

Brand is green-led (leaf/olive greens that echo the frog mascot) on a Notion-light neutral canvas,
with a warm **amber** streak accent and a **teal** focus accent. Map each token to an
`Assets.xcassets` color set using the light + dark values below.

| Token | Light | Dark | Use |
|-------|-------|------|-----|
| `brand/green` | #3DA35D | #4FB870 | primary actions, active timer, selection |
| `brand/greenDeep` | #256B3E | #2E7D49 | headers, emphasis, mascot tie-in |
| `brand/greenSoft` | #E7F4EA | #1C2A20 | green-tinted cards / success surfaces |
| `accent/streak` | #F5A524 | #F6B24A | streak flame, rewards, XP |
| `accent/focus` | #2FA5A5 | #3BBEBE | Focus Mode, secondary highlights |
| `state/success` | #2E9E4F | #46B968 | correct answer, completed |
| `state/danger` | #E5533D | #F26A54 | destructive, wrong answer |
| `bg/canvas` | #FFFFFF | #15181A | app background |
| `bg/surface` | #F6F7F4 | #1D211E | cards, sheets (Notion off-white) |
| `bg/surfaceAlt` | #EDEFEA | #262B27 | secondary surface |
| `border/subtle` | #E4E6DF | #313731 | hairline borders |
| `text/primary` | #1E241F | #ECEFEA | headings / body |
| `text/secondary` | #6A6F67 | #9AA097 | captions, meta |

> Rule: **use tokens, never raw hex in views.** Define once in `Core/DesignSystem/Colors.swift`.
> Fonts remain SF Pro (Dynamic Type) until a brand font is locked (see §3).

## 3. Typography (PLACEHOLDER)

- **UI font:** system **SF Pro** (Dynamic Type) as the safe default until a brand font is chosen.
  Candidate brand fonts to evaluate: Inter, General Sans, or a rounded face for warmth.
- **Mascot/story display:** a **pixel font** (e.g. a licensed pixel typeface) for story cards &
  mascot dialogue to reinforce the pixel-art theme — used sparingly, never for body text.

Type scale (points, scales with Dynamic Type):

| Style | Size / weight |
|-------|---------------|
| Display | 34 / bold |
| Title | 28 / bold |
| Headline | 20 / semibold |
| Body | 17 / regular |
| Callout | 15 / regular |
| Caption | 13 / regular |

## 4. Spacing & radius

- Spacing scale (pt): 4, 8, 12, 16, 20, 24, 32, 40.
- Corner radius: cards 16, buttons 12, sheets 24, mascot chips 20.
- Standard screen padding: 20pt horizontal.

## 5. Elevation

Prefer **soft, low shadows** over hard ones (Notion feel): e.g. y=2, blur=8, 6–8% black. Use
borders (`border/subtle`) more than shadows for separation.

## 6. Core components (to build in `Core/DesignSystem`)

- `PrimaryButton`, `SecondaryButton`, `IconButton`
- `Card` (surface + radius + optional border)
- `StatTile` (big number + label)
- `SegmentedControl`, `Chip/Tag`
- `ProgressRing` (Pomodoro), `ProgressBar` (goals)
- `StreakBadge` (flame + count)
- `MascotView` (sprite host, see `05-MASCOT.md`)
- `StoryCard` templates (9:16)
- `EmptyState`, `Toast`, `Sheet` wrapper

## 7. Motion

- Durations: 150ms (micro), 250ms (standard), 400ms (celebratory).
- Easing: ease-in-out standard; spring for mascot & celebrations.
- Always honor **Reduce Motion** (swap animations for cross-fades).

## 8. Iconography

SF Symbols for UI. Pixel-art custom icons only for gamified/mascot surfaces.

## 9. Dark mode

Every token has a dark variant. Canvas ~#1A1A19, surface ~#232322, text inverted. Mascot sprites
need dark-safe outlines.

## 10. Localization

UI copy in **PT-BR** via `Localizable.xcstrings`. No hard-coded strings in views. Keep copy warm
and in the mascot's voice for nudges.

---

### TODO before build-heavy UI work
- [x] Brand palette locked — green-based (§2).
- [ ] Choose brand font + pixel font (licensing check).
- [x] Mascot direction approved — frog (`05-MASCOT.md`).
