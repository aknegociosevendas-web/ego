# CLAUDE.md — EGO project context

> This file is auto-loaded by Claude when coding in the terminal. Keep it short, accurate, and
> current. It tells the agent how to build EGO correctly.

## What we're building
**EGO** — a native iOS (iOS 17+) focus & study app in **Swift/SwiftUI**. Pomodoro, Focus Mode
(app blocking via Screen Time APIs), Duolingo-style streaks, an interactive **pixel-art mascot**,
study routines, a vestibular/ENEM question bank, essay (redação) frameworks, topic goals, and
shareable stats. Target user: Brazilian students prepping for vestibular/ENEM.

## Golden rules
1. **Read the docs first.** Source of truth is `/docs`. Start with `01-FEATURES.md` (feature IDs
   F-xx), then the relevant deep-dive doc. Don't invent behavior — follow the spec or ask.
2. **UI language = PT-BR** (all user-facing strings, via `Localizable.xcstrings`, no hard-coded
   strings). **Code, comments, docs = English.**
3. **Design = Notion-like, light, minimal.** Use design tokens from `Core/DesignSystem` — never
   raw hex/fonts in views. Palette & fonts are placeholders (`04-DESIGN-SYSTEM.md`) until locked.
4. **Architecture = MVVM + feature modules** (`02-ARCHITECTURE.md`). Views dumb; ViewModels own
   state (`@Observable`); repositories own persistence. ViewModels never import SwiftData directly.
5. **Persistence = SwiftData + CloudKit** (private DB) from day one. Respect CloudKit constraints:
   attributes optional/defaulted, relationships optional, **every relationship must declare its
   inverse (`@Relationship(inverse:)`)**, no unique constraints (`03-DATA-MODEL.md`). Test at least
   once against a real `ModelContainer` (not just in-memory) after any schema change.
   **Never touch SwiftData (contexts/repositories) from a detached `Task`** — do repository work
   synchronously on the MainActor and let the task capture only value payloads/schedulers; a
   fire-and-forget task can outlive the `ModelContainer` and trap (bit us 3×).
6. **The mascot reacts to events.** When you build a feature that completes a session/goal/streak,
   wire the corresponding mascot state (`05-MASCOT.md`).
7. **Keep changes surgical.** Small, focused diffs. Don't refactor unrelated code. Prefer
   first-party frameworks; add SPM deps only when justified.
8. **Test the math.** Unit-test gamification (XP/coins/streak), SM-2 spaced repetition, repositories
   (in-memory ModelContainer).

## Tech stack
Swift 5.9+ · SwiftUI · SwiftData + CloudKit · Swift Concurrency · FamilyControls/ManagedSettings/
DeviceActivity (Focus Mode) · WidgetKit/ActivityKit · UserNotifications · Swift Charts.

## Folder layout (see 02-ARCHITECTURE.md)
`App/` · `Core/{Persistence,Services,DesignSystem,Extensions,Utilities}` ·
`Features/{Focus,FocusMode,Streak,Routines,QuestionBank,Essays,Reminders,Goals,Stats,Mascot,
Gamification,Social,Onboarding,Settings}` · `Extensions/{Shield*,DeviceActivityMonitor,Widgets}` ·
`Resources/` · `Tests/`.

## Build order (see 09-ROADMAP.md)
Phase 0 foundations → Phase 1 core habit loop (Pomodoro, mascot, streak, stats, XP) →
Phase 2 Focus Mode + routines + goals → Phase 3 question bank + essays → Phase 4 social + widgets +
story cards → Phase 5 polish/launch.

## Critical constraints
- **Family Controls entitlement** is required for app-blocking and needs Apple approval — build the
  soft-focus fallback in parallel (`06-SCREEN-TIME-FOCUS.md`). Test blocking on a real device.
- **Question-bank content** has licensing implications — start with ENEM/INEP + original items
  (`08-CONTENT-BANKS.md`). Never reproduce copyrighted questions verbatim.
- Honor **Reduce Motion** and **Dynamic Type**; accessibility is non-negotiable.

## Workflow expectations
- Work feature-by-feature (one F-xx at a time). State which feature and phase you're on.
- After code changes, build and run tests. Report what you changed and why, concisely.
- If a spec is ambiguous or missing, ask before guessing.
- Don't create files/folders outside the agreed structure without saying so.

## Definition of done (per feature)
Works offline, syncs via CloudKit, mascot reacts, stats update, PT-BR copy in place, matches the
design system, has tests for any non-trivial logic.
