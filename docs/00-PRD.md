# 00 — Product Requirements Document (PRD)

## 1. Vision

**EGO** is a native iOS focus & study app that turns studying into a daily habit through a
Pomodoro engine, a real app-blocking Focus Mode, Duolingo-style streaks, and an interactive
**pixel-art mascot** that reacts to the student's behavior. It targets Brazilian students
preparing for **vestibular / ENEM**, combining focus tooling with study content (routines,
past-exam question bank, essay frameworks) and shareable, competitive stats.

**One-liner (PT-BR):** *"Foco, rotina e constância para passar no vestibular — com um bichinho
que estuda com você."*

## 2. Positioning

EGO is not "just a Pomodoro timer" and not "just a question bank". It is the **habit layer**
that sits between the student and their study material: it makes them show up daily (streak +
mascot + focus mode), gives them something to do (routines, goals, question bank, essays), and
proves progress (stats, stories, ranking). The product sells **constância e resultado**, not a tool.

## 3. Target personas

1. **Vestibulanda(o) intensivo** — 16–19 y/o, studying for ENEM/vestibular, easily distracted by
   the phone, motivated by streaks and social proof. Primary persona.
2. **Universitário / concurseiro** — 18–28 y/o, needs routine + focus + stats to stay consistent.
3. **Autodidata** — studies courses/skills, wants Pomodoro + habit tracking + a fun companion.

## 4. Goals & success metrics

| Goal | Metric | Target (v1 north star) |
|------|--------|------------------------|
| Habit formation | D1 / D7 / D30 retention | D7 ≥ 35%, D30 ≥ 18% |
| Daily engagement | % DAU starting ≥1 focus session | ≥ 60% of DAU |
| Streak health | Median active streak length | ≥ 7 days |
| Focus depth | Avg focused minutes / active day | ≥ 50 min |
| Virality | % users sharing a story card / week | ≥ 8% |
| Content pull | % users using question bank or essays weekly | ≥ 30% |

## 5. Scope (v1 = full feature set)

Per stakeholder decision, v1 targets the **complete** feature list. Delivery is phased for
engineering sanity (see `09-ROADMAP.md`) but the product design assumes all of:

Pomodoro · Focus Mode (app blocking) · Motivational notifications · Streak system · Study
routines · 6-month routine history · Vestibular/ENEM question bank · Essay (redação) frameworks
· Study reminders · Topic goals · Profile stats (shareable) · Story layouts · Interactive
pixel-art mascot · CloudKit sync. Plus validated additions from research: focus-coin economy,
XP/levels, streak freeze, co-study rooms, spaced repetition, widgets/Live Activities.

Full functional detail: `01-FEATURES.md`.

## 6. Non-goals (v1)

- Android / web app (iOS-native only for now).
- Full LMS / video courses.
- AI tutor / chat (may come later as an add-on).
- Marketplace or user-generated question selling.

## 7. Constraints & assumptions

- **iOS 17+**, SwiftUI-first, CloudKit from day one (no custom backend in v1).
- **Family Controls entitlement** required for Focus Mode app-blocking — must be requested from
  Apple; feature ships behind that approval. Fallback: soft focus (notifications + Screen Time
  suggestions) until entitlement is granted.
- Question-bank content sourcing must respect licensing (see `08-CONTENT-BANKS.md`).
- Built primarily with **Claude Fable 5** in terminal + Xcode, later **Opus** for complex modules.

## 8. Key risks

| Risk | Impact | Mitigation |
|------|--------|-----------|
| Family Controls entitlement denied/delayed | Focus Mode blocked | Ship soft-focus fallback; apply early |
| Content licensing (vestibular banks) | Legal | Start with public ENEM/INEP items + original items |
| Scope too large for v1 | Slippage | Phase the roadmap; keep a shippable "core" milestone |
| Mascot animation cost | Delays | Pixel-art sprite sheets are cheap; reuse states |
| Leaderboards demotivate some users | Churn | All social features opt-in; non-competitive mode |

## 9. Definition of done (product level)

A build is "done" for a milestone when: the feature works offline and syncs via CloudKit, the
mascot reacts to the relevant event, stats update correctly, PT-BR copy is in place, and the
screen matches the Notion-like light design system.
