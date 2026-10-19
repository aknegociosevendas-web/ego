# 05 — Mascot (Pixel-Art, Interactive)

The mascot is EGO's personality and its #1 retention lever (see research: Duo, Finch). Art
direction is **pixel-art in the "Claude companion" chibi style** (rounded body, soft shading,
little feet, blush cheeks, one strong concept), with **fluid, code-driven animation** (squash &
stretch, breathe, blink) rather than only frame flipping.

> ✅ **LOCKED CONCEPT: a FROG (sapo).** Chosen for strong readable silhouette, expressive face
> (big eyes + blush), rich emotion range, and a natural evolution arc (girino → sapo → sapo mestre).
> A visual reference is being provided by the stakeholder — match its silhouette, palette, and
> proportions. The concept options in §2 below are kept for history only; **build the frog.**

## 1. Design principles (from research)

The most retention-effective mascots share three traits EGO must copy:
1. **Personality with stakes** — reacts emotionally to behavior (proud, worried, sad).
2. **Growth tied to real actions** — visibly evolves as you study, not on a random timer.
3. **A reason to return** — "seu parceiro precisa de você hoje" — a caring nudge, not pure guilt
   (Finch's affection model retains better than Duo's guilt alone).

Plus EGO-specific: **pixel-art**, **name it in onboarding** (ownership), **skinnable** (economy).

## 2. Concept options (pixel-art) — pick one

> All work as ~32×32 or 48×48 base sprites, scalable, with a consistent 4–8 color palette.

### A. 🦉 **Coruja "EGO"** — the studious owl
- Owl = classic study/wisdom symbol; friendly, familiar (Duo-adjacent but pixel + owns the name).
- Grows from chick → wise owl with your streak. Wears graduation cap skins.
- **Pros:** instantly readable as "study", proven category. **Cons:** closest to Duolingo.

### B. 🧠 **"Cérebro" / brain-buddy** — on-brand with "EGO"
- A cute pixel brain with legs/eyes — literally your mind/ego studying with you.
- Strongest **brand tie to the name EGO** and differentiates from animal mascots.
- Evolves: sleepy small brain → glowing "big brain" at high levels/streaks.
- **Pros:** unique, memorable, meme-friendly for stories. **Cons:** must be cute, not gross.

### C. 🦊 **Raposa foco** — the focus fox
- Clever, warm, popular in indie/pixel aesthetics; pairs with a "Forest"-like vibe.
- Curls up asleep when you're inactive; alert & studying during focus.
- **Pros:** high charm, great for skins. **Cons:** generic (many apps use foxes).

### D. 🐣 **Pintinho/ave companheira** — the Finch-style buddy
- A little bird you "raise"; thrives from your real study actions (Finch's proven model).
- Hatches in onboarding; grows/evolves with consistency.
- **Pros:** proven affection loop, emotional. **Cons:** similar to Finch.

### E. 👾 **"Blob/slime" pixel** — minimalist mascot
- A simple expressive blob (Notion/Claude-adjacent minimalism, but pixel).
- Easiest to animate; endless facial expressions; morphs shape by mood.
- **Pros:** cheapest to animate, super clean, fits the minimal UI. **Cons:** less "study" meaning.

### F. 🤖 **Robôzinho de estudo** — the study bot
- A tiny retro robot companion (fits pixel-art/8-bit heritage perfectly).
- "Powers up" with XP; low battery when you skip days.
- **Pros:** strong pixel/8-bit identity, battery = clever streak metaphor. **Cons:** less warm.

### G. 🐉 **Dragãozinho** — the growing dragon
- Tiny egg → small dragon → mighty dragon as you level up (RPG framing, Focus Quest vibe).
- Great long-term progression fantasy for a 6-month exam grind.
- **Pros:** powerful growth arc, epic story cards. **Cons:** more sprites to draw per evolution.

### Recommendation
**B (Cérebro/brain-buddy)** for brand uniqueness + perfect fit with the name *EGO*, **or**
**E (Blob)** if you want the cheapest-to-animate, cleanest match to the minimal Notion UI.
If you want maximum proven-retention safety, **D (Finch-style bird)** or **A (owl)**. My pick:
**B**, with a blob-like simplicity of expression so it's cheap to animate. Final call is yours.

## 3. State machine (applies to whichever concept)

| State | Trigger | Animation |
|-------|---------|-----------|
| `idle` | default on Home | slow blink/breathe loop |
| `studying` | focus session running | reading/writing loop |
| `celebrating` | session complete / goal / level-up | jump + confetti |
| `sad` | session abandoned / streak broken | droop, small tear |
| `worried` | streak at risk (late in day) | fidget, look at clock |
| `sleeping` | app idle / night | Zzz loop |
| `levelUp` | level increase | glow + evolve flash |
| `cheering` | milestone / correct-answer streak | pump fist |
| `guarding` | shown on Focus Mode shield | arms-crossed "blocked" pose |

Moods also scale with streak length (happier the longer the streak).

## 4. Evolution / growth

- Visual tiers tied to **level** and/or **longest streak** (e.g. tiers at level 1/5/10/20/40).
- Each tier = a new sprite set (bigger/cooler). Reinforces long-term study.
- Skins/accessories (coin economy) layer on top of the current tier.

## 4b. Production pipeline — how the frog sprite is actually made

Three ways to produce the art; EGO uses a hybrid.

| Path | What it is | Use for | Verdict |
|------|-----------|---------|---------|
| **Procedural (code)** | Frog defined as a pixel matrix (data) drawn in a SwiftUI `Canvas` with `.interpolation(.none)`; animated by code transforms (squash/stretch, bob, blink, blush) | Base frog + core states (idle/studying/celebrating/sad) | **Primary.** No API, no artist, pixel-perfect, tiny asset, reacts to events live. Deterministic — the agent can generate it. |
| **Hand-drawn sprite sheets** | Frames authored in Aseprite/Piskel | Evolution tiers, skins, elaborate special frames | **Polish phase.** Best art quality (how Claude's mascots are made); needs a pixel artist or agent-generated grid refined by a human. |
| **AI image generation** | Gemini/Flux via an image skill | Concept exploration only | **Brainstorm only.** AI can't keep frame-to-frame consistency or an exact pixel grid → not usable for real sprite sheets. |

**Decision:** build the base frog + core states **procedurally in code** (no external dependency);
add hand-drawn sprite sheets later for evolution/skins; use AI only to explore looks. The same
pixel-matrix + animation logic prototyped in HTML/Canvas ports directly to SwiftUI `Canvas`.

## 5. Technical animation plan

- **Sprite sheets** per state (row = state, columns = frames). PNG in `Assets.xcassets` or bundled.
- A `SpriteAnimator` drives frame timing (e.g. `TimelineView`/`CADisplayLink` or a `Canvas` loop).
- `MascotView` = SwiftUI host exposing `.state(_:)`; ViewModels set state from app events.
- Prefer **nearest-neighbor scaling** (`.interpolation(.none)`) to keep pixels crisp.
- Keep frame counts small (4–8) for size/perf; reuse frames across states.
- Honor **Reduce Motion** (hold a static expressive frame instead of looping).
- Optional: a tiny "tap the mascot" reaction (delight) with a random cheer.

## 6. Voice & copy (PT-BR)

- Caring, upbeat, a little playful; never mocking. Speaks in short lines.
- Examples: "Bora focar? 👀", "Você tá on fire — 12 dias! 🔥", "Senti sua falta ontem…",
  "Faltam 10 min pra sua meta de hoje!"
- Used in notifications, shield screen, story cards, empty states.

## 7. Assets to produce (once concept is locked)
- [ ] Base sprite (idle) + palette.
- [ ] Sprite sheets for all states (§3).
- [ ] Evolution tiers (§4).
- [ ] A starter set of skins/accessories for the economy.
- [ ] Story-card poses (§F-12).
- [ ] App icon featuring the mascot.

## 8. Open decisions
- [ ] **Pick a concept (A–G).**
- [ ] Confirm base resolution (32×32 vs 48×48) & palette.
- [ ] Name suggestions for the mascot (or let users name it in onboarding).
