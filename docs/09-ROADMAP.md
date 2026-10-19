# 09 — Roadmap

Scope is the **full feature set**, delivered in phases so each milestone is shippable/testable.
Build order optimizes for: (1) core habit loop first, (2) content next, (3) social/polish last.
Coding with **Fable 5** early, **Opus** for complex modules (Focus Mode extensions, sync, SM-2).

## Phase 0 — Foundations (project setup)
- Xcode project, folder modules (`02-ARCHITECTURE.md`), SwiftLint/SwiftFormat.
- Design system tokens & core components (placeholders from `04`).
- SwiftData + **CloudKit** container wired; base entities (`03-DATA-MODEL.md`).
- App shell: tab router, onboarding skeleton (F-17).
- **Exit:** app builds, syncs an entity via CloudKit, design tokens in place.

## Phase 1 — Core habit loop (the heart of EGO)
- **F-01 Pomodoro** (+ Live Activity F-16 basic).
- **F-13 Mascot** engine with core states (idle/focused/celebrate/sad).
- **F-04 Streak** system (+ freeze).
- **F-11 Stats** dashboard (basic) + **F-03/F-09 Reminders/notifications**.
- **F-14 Gamification** base (XP, coins, levels).
- **Exit:** a user can focus daily, keep a streak, see the mascot react, earn XP/coins.

## Phase 2 — Focus Mode & study structure
- **F-02 Focus Mode** app blocking (entitlement-gated) + soft-focus fallback (`06`).
- **F-05 Routines** + **F-06 6-month history**.
- **F-10 Topic Goals** (sessions/attempts attribute to goals & stats).
- **Exit:** blocking works on device; routines/goals drive the dashboard.

## Phase 3 — Content (vestibular/ENEM)
- **F-07 Question bank** (browse/practice/review) + **SM-2 spaced repetition**.
- **F-08 Essay frameworks** (templates, rubric, drafts, repertório flashcards).
- Content pipeline & licensing resolved (`08-CONTENT-BANKS.md`).
- **Exit:** students can practice questions and structure essays inside EGO.

## Phase 4 — Sharing & social
- **F-12 Story cards** (all templates) + full **F-11** shareable stats.
- **F-15 Co-study rooms** + opt-in weekly ranking (CKShare).
- **F-16** full widgets/Live Activities/Lock Screen.
- **Exit:** users share progress and study together.

## Phase 5 — Polish, beta, launch
- Full PT-BR copy pass in mascot voice; accessibility; dark mode.
- Performance, CloudKit conflict hardening, empty/error states.
- TestFlight beta → iterate → App Store submission (privacy, Family Controls review).

## Cross-cutting (every phase)
- Unit tests for gamification/streak/SM-2 math; repository tests on in-memory store.
- Mascot reaction wired for each new event.
- Keep a shippable build at each phase exit.

## Critical dependencies / watch items
- **Family Controls entitlement** → blocks Phase 2 blocking (apply in Phase 0).
- **Question-bank licensing** → blocks Phase 3 content (resolve in Phase 1/2).
- **Mascot art direction & palette/fonts** → needed before Phase 1 UI polish.
