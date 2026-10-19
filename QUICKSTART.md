# QUICKSTART — Start building EGO

Kickoff steps to go from zero to a running Phase 0 build, coding with Claude (Fable 5) in the
terminal + Xcode. Full spec is in `/docs`; the coding prompt is in `prompts/FABLE5-INIT-PROMPT.md`.

## Prerequisites (once)
- **Xcode** installed (Mac App Store).
- Sign in Xcode: *Settings › Accounts* with your Apple ID.
- **Apple Developer Program (paid)** is needed for CloudKit + testing app-blocking on a real
  device. You can start on the **Simulator** without it and add CloudKit later.
- Claude CLI installed and logged in.

## Step 1 — Create the Xcode project
1. Xcode → *File › New › Project… › iOS › App*.
2. Product Name **EGO** · Interface **SwiftUI** · Language **Swift** · Storage **None**.
3. Organization Identifier: `com.akai` (or your domain).
4. **Save it inside this folder** (`EGO - ESTUDO`) so code + docs live together.
5. *Project › General* → **Minimum Deployments = iOS 17.0**.

## Step 2 — Launch Claude (Fable 5) in this folder
```bash
cd ~/Documents/akai/"EGO - ESTUDO"
claude
```
Inside Claude: `/model` → select **claude-fable-5**. `CLAUDE.md` and `/docs` load automatically.

## Step 3 — Paste the first prompt
Open `prompts/FABLE5-INIT-PROMPT.md`, copy the whole block under "▶️ PASTE THIS", and paste it.
(Shortcut you can paste instead:)
```
Leia CLAUDE.md e /docs (comece por 01-FEATURES e 02-ARCHITECTURE).
Estamos na Fase 0 (Fundações). Siga prompts/FABLE5-INIT-PROMPT.md:
comece pelo PLANO (passo 1), sem código, e espere meu "go".
```
Review its **plan**, then reply **`go`** to let it scaffold Phase 0 (folders, design tokens with the
locked green palette, SwiftData + CloudKit, DI, TabView shell, onboarding skeleton, 1 unit test).

## Step 4 — Build & run
1. In Xcode, if new files don't appear, *File › Add Files to "EGO"…* and add the created folders.
2. Pick a simulator (e.g. iPhone 15) → **Cmd + R**.
3. CloudKit (optional now): *Signing & Capabilities › + Capability › iCloud › CloudKit* + create a
   container (needs the paid account).

## Step 5 — Development loop
- Ask for the next feature in the terminal, e.g.:
  `Fase 1: implemente F-01 Pomodoro + F-13 mascote (idle/estudando/feliz/triste) + F-04 streak, seguindo os docs.`
- Build/run in Xcode after each step.
- Switch to **Opus** (`/model`) for hard modules: Focus Mode extensions, CloudKit conflicts, SM-2.

## Mascot note
Frog art direction + animation reference: `assets/mascot/` (open `frog-prototype.html` to see the
motion; `MASCOT-ANIMATION-REFERENCE.md` explains the SwiftUI port). Match the stakeholder's
reference image for final art.

## Handy references
- Feature IDs & behavior → `docs/01-FEATURES.md`
- Architecture & folders → `docs/02-ARCHITECTURE.md`
- Data model (CloudKit-safe) → `docs/03-DATA-MODEL.md`
- Design tokens (locked green palette) → `docs/04-DESIGN-SYSTEM.md`
- Build order → `docs/09-ROADMAP.md`
