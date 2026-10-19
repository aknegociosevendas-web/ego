# Fable 5 — Optimized Kickoff Prompt (EGO)

How to use: open a terminal Claude session **in the project root** (so `CLAUDE.md` and `/docs`
load automatically), then paste the prompt in the block below. It's structured with the
prompt-engineering pattern that works best for capable coding models: **clear role → rich context
→ explicit objective → constraints → precise task → workflow → output format → success criteria →
guardrails**, with XML tags so the model can parse each section cleanly.

Tips:
- Keep this as the **first** message of the session (Phase 0). Subsequent phases reuse the
  `<workflow>` and `<guardrails>` and just swap the `<objective>`/`<task>`.
- Be explicit; give it the feature IDs and the docs to read. Don't make it guess.
- Ask for a **plan before code** on anything non-trivial.

---

## ▶️ PASTE THIS

```text
<role>
You are a senior iOS engineer building a native SwiftUI app called EGO. You write clean,
idiomatic, production-quality Swift, follow the project's architecture exactly, and make small,
surgical, well-tested changes. You read the project docs before acting and you ask when a spec is
ambiguous instead of guessing.
</role>

<context>
EGO is a native iOS (iOS 17+) focus & study app for Brazilian students preparing for
vestibular/ENEM. Features: Pomodoro, Focus Mode (app blocking via Screen Time APIs), Duolingo-style
streaks, an interactive pixel-art mascot, study routines with 6-month history, a vestibular/ENEM
question bank with spaced repetition, essay (redação) frameworks, topic goals, and shareable stats.

The full specification lives in this repo:
- CLAUDE.md — project rules (read first).
- docs/00-PRD.md — vision, goals, personas.
- docs/01-FEATURES.md — every feature with IDs F-01…F-18 (source of truth for behavior).
- docs/02-ARCHITECTURE.md — stack, MVVM + feature modules, folder layout.
- docs/03-DATA-MODEL.md — SwiftData/CloudKit entities.
- docs/04-DESIGN-SYSTEM.md — Notion-like light design tokens (placeholders).
- docs/05-MASCOT.md — pixel-art mascot state machine.
- docs/06-SCREEN-TIME-FOCUS.md — Focus Mode implementation + entitlement notes.
- docs/07-GAMIFICATION.md — streaks, XP, coins, stats, story cards.
- docs/08-CONTENT-BANKS.md — question bank, essays, routine templates.
- docs/09-ROADMAP.md — phased build order.

Non-negotiable rules:
- UI strings in Portuguese (PT-BR) via Localizable.xcstrings — no hard-coded strings in views.
- Code, comments, and docs in English.
- Design is Notion-like, light, minimal; use design tokens, never raw hex/fonts in views.
- Architecture is MVVM + feature modules. Views are dumb; ViewModels own state (@Observable);
  repositories own persistence. ViewModels never import SwiftData directly.
- Persistence is SwiftData + CloudKit (private DB) from day one, respecting CloudKit constraints
  (attributes optional/defaulted, relationships optional, no unique constraints).
</context>

<objective>
Execute ROADMAP Phase 0 (Foundations): scaffold the Xcode project structure, design-system tokens,
persistence layer (SwiftData + CloudKit) with the base entities, dependency injection, the app
shell (tab router), and an onboarding skeleton — so the app builds, syncs one entity via CloudKit,
and has the design tokens and module folders in place. Do NOT build feature logic yet (that's
Phase 1); just the foundation everything else plugs into.
</objective>

<tech_constraints>
- Swift 5.9+, SwiftUI, iOS 17+ deployment target.
- SwiftData with CloudKit private database on the ModelContainer.
- Swift Concurrency (async/await, actors) for side effects.
- First-party frameworks only in Phase 0. No third-party SPM packages unless you justify one and I approve.
- Respect Reduce Motion and Dynamic Type from the start.
</tech_constraints>

<task>
Deliver Phase 0 in these ordered steps. Pause for my approval after step 1 (the plan).

1. PLAN: Read CLAUDE.md, docs/02-ARCHITECTURE.md, docs/03-DATA-MODEL.md, docs/04-DESIGN-SYSTEM.md.
   Produce a short implementation plan: exact files/folders you'll create, the base SwiftData
   entities you'll define first (start with UserProfile, UserStats, FocusSession, Streak), how you'll
   wire CloudKit, and how DI will work. List assumptions and any spec gaps. Wait for my "go".

2. PROJECT STRUCTURE: Create the folder/module layout from docs/02-ARCHITECTURE.md
   (App/, Core/{Persistence,Services,DesignSystem,Extensions,Utilities}, Features/…, Resources/, Tests/).

3. DESIGN SYSTEM: Implement Colors.swift and Typography.swift as semantic tokens mapping to
   Assets color sets (use the LOCKED green palette from docs/04 §2), plus Spacing/Radius constants and
   2–3 core components (Card, PrimaryButton, StatTile). Light + dark variants.

4. PERSISTENCE: Define the base SwiftData @Model entities (CloudKit-safe per docs/03), configure a
   ModelContainer with CloudKit private DB, and a protocol-based repository for one entity
   (e.g. FocusRepository) with an in-memory variant for tests/previews.

5. APP SHELL + DI: EGOApp.swift (@main) wiring ModelContainer + a small DIContainer; an AppRouter
   with a TabView (placeholder tabs: Início, Estudar, Estatísticas, Perfil) in PT-BR; a minimal
   onboarding skeleton screen.

6. VERIFY: Ensure it builds; add a trivial unit test proving the in-memory repository saves/fetches;
   confirm CloudKit capability requirements are documented in the PR notes.
</task>

<workflow>
- Work in the order above. State which step you're on.
- For each step: briefly say what you'll change, make the change, then summarize the diff.
- Prefer many small files over a few huge ones; one type per file where reasonable.
- If a spec is ambiguous or missing, STOP and ask a specific question rather than guessing.
- Don't create files outside the agreed structure without calling it out.
</workflow>

<output_format>
- Start with the PLAN (step 1) as prose + a file tree. No code until I say "go".
- After approval, for each step output: (a) one-line intent, (b) the code/files, (c) a short
  "what changed & why". Keep commentary tight.
- Use fenced code blocks with correct file paths as headers.
</output_format>

<success_criteria>
Phase 0 is done when: the project builds on an iOS 17 simulator; the folder modules match
docs/02; design tokens exist and are used by the sample components; the base SwiftData entities are
CloudKit-safe and a ModelContainer with CloudKit private DB is configured; a DIContainer wires the
app; the TabView shell + onboarding skeleton render in PT-BR; and one unit test passes proving the
repository works. No feature logic beyond scaffolding.
</success_criteria>

<guardrails>
- Follow the docs; don't redesign the architecture or data model unilaterally — propose changes and
  wait for approval.
- No hard-coded user-facing strings; PT-BR via Localizable.xcstrings.
- No raw hex/fonts in views; use design tokens.
- Keep diffs surgical; don't touch unrelated code.
- Note anything that needs the Apple Developer portal (iCloud/CloudKit container, later Family
  Controls entitlement) so I can configure it.
</guardrails>
```

---

## Why this prompt works (the "formula")

1. **`<role>`** sets identity + standards (senior iOS, surgical, reads docs, asks when unsure).
2. **`<context>`** front-loads everything the model needs and points to the docs (the model
   shouldn't reconstruct the project from memory).
3. **`<objective>`** is a single, scoped goal (Phase 0 only) — prevents over-building.
4. **`<tech_constraints>`** removes ambiguity on stack decisions.
5. **`<task>`** is an explicit, ordered checklist with a **plan-before-code gate** (step 1) — the
   biggest quality lever for coding models.
6. **`<workflow>` / `<output_format>`** shape *how* it responds (small diffs, ask-don't-guess,
   structured output) → easier to review.
7. **`<success_criteria>`** gives a testable definition of done.
8. **`<guardrails>`** encodes the non-negotiables so the model can't drift.

## Reusing for later phases
Keep `<role>`, `<context>`, `<tech_constraints>`, `<workflow>`, `<output_format>`, `<guardrails>`
identical. Swap `<objective>` + `<task>` to the next roadmap phase and name the specific feature IDs
(e.g. "Phase 1: implement F-01 Pomodoro + F-13 mascot core states + F-04 streak"). Always keep the
**plan-before-code** gate for non-trivial work.

## Model note
Start with **Fable 5** for scaffolding and straightforward features; switch to **Opus** for the
hard modules (Focus Mode extensions, CloudKit conflict handling, SM-2 scheduler, sprite animation
engine). Same prompt structure applies to both.
