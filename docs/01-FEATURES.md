# 01 — Feature Specification

Every feature EGO ships, with behavior, data touchpoints, and mascot hooks. IDs (F-xx) are
referenced across docs, roadmap, and the build prompt.

Legend: **Mascot hook** = how the pixel-art mascot reacts. **Data** = entities touched (see `03-DATA-MODEL.md`).

---

## F-01 · Pomodoro Timer
- Configurable focus / short break / long break (default 25/5/15), cycles before long break (default 4).
- Presets (e.g. "ENEM 50/10", "Deep 90/20") + custom.
- Start / pause / skip / reset. Runs in background; **Live Activity** + Lock Screen + Dynamic Island.
- Optional ambient sounds (white noise, lo-fi, rain) and ticking toggle.
- Each session can be **attached to a Topic Goal / subject** so time auto-attributes to stats.
- **Mascot hook:** mascot "studies" alongside during focus (focused sprite), celebrates on complete, looks sad on early quit (loss-aversion).
- **Data:** `FocusSession`, `TopicGoal`, `UserStats`.

## F-02 · Focus Mode (App Blocking)
- Blocks user-selected distracting apps/categories for the session duration using Apple **Screen Time APIs** (FamilyControls + ManagedSettings + DeviceActivity). See `06-SCREEN-TIME-FOCUS.md`.
- Shield screen with EGO branding + mascot + motivational line when a blocked app is opened.
- "Hard mode" (no early unlock) vs "Soft mode" (unlock with friction/confirmation).
- Fallback when entitlement unavailable: strong notifications + iOS Focus/Shortcuts suggestion.
- **Mascot hook:** mascot appears on the shield screen guarding the user.
- **Data:** `FocusSession`, `BlockProfile`.

## F-03 · Motivational Notifications
- Scheduled push/local notifications with motivational phrases (PT-BR), curated + rotating.
- Triggers: streak-at-risk, session reminder, comeback nudge, goal progress, milestone.
- Tone follows the mascot's "caring, not guilt-tripping" persona (Finch-style) with optional Duo-style edge.
- **Mascot hook:** notification copy is "from" the mascot; avatar in rich notification.
- **Data:** `Reminder`, `NotificationTemplate`, `Streak`.

## F-04 · Streak System (Duolingo-style)
- Daily streak increments when the day's minimum goal is met (e.g. ≥1 completed focus session or ≥X min).
- **Streak freeze / repair** (earned or limited) to prevent rage-quit churn.
- Streak milestones (7/30/100/365) unlock rewards (mascot skins, badges, story cards).
- Weekly "streak calendar" heatmap.
- **Mascot hook:** mascot mood scales with streak; celebration animation on milestones; worried at risk.
- **Data:** `Streak`, `UserStats`, `Reward`.

## F-05 · Study Routines
- Build a weekly routine: blocks per day (subject, duration, target sessions).
- Templates (e.g. "ENEM 6 meses", "Concurso", "Revisão pré-prova").
- Daily agenda view; check off blocks; auto-suggest today's next block.
- **6-month routine history** (F-06) feeds analytics.
- **Mascot hook:** mascot reacts to routine completion rate.
- **Data:** `Routine`, `RoutineBlock`, `RoutineLog`.

## F-06 · Routine History (last 6 months)
- Rolling 6-month store of completed routines/blocks/sessions.
- Trends: consistency %, minutes by subject, best days/times.
- Powers "regenerate a routine based on what actually worked".
- **Data:** `RoutineLog`, `FocusSession`, `UserStats`.

## F-07 · Vestibular/ENEM Question Bank
- Browse/filter past-exam questions by exam, year, subject, topic, difficulty.
- Practice mode (timed/untimed), answer, see explanation, mark for review.
- **Spaced repetition (SM-2)** review queue for missed/marked questions.
- Performance by subject/topic feeds stats + routine suggestions.
- Content sourcing & licensing: see `08-CONTENT-BANKS.md`.
- **Mascot hook:** reacts to correct/incorrect; celebrates streaks of correct answers.
- **Data:** `Question`, `QuestionAttempt`, `ReviewItem`, `TopicGoal`.

## F-08 · Essay (Redação) Frameworks
- Structured templates for ENEM/vestibular essays (dissertativo-argumentativo, intro/dev/conclusão, proposta de intervenção).
- Repertório/argument bank, connectives, competency checklist (ENEM 5 competências).
- Writing space with word count + timer; save drafts; self-score against rubric.
- Optional flashcards of repertório for spaced repetition.
- **Mascot hook:** encourages during writing; celebrates a finished essay.
- **Data:** `EssayTemplate`, `EssayDraft`, `Rubric`.

## F-09 · Study Reminders
- Time-based and routine-based reminders; per-subject; smart "you usually study now" nudges.
- Snooze, recurring, quiet hours.
- **Data:** `Reminder`.

## F-10 · Topic Goals
- Create goals per subject/topic: target hours, target questions, target essays, deadline.
- Progress bars; auto-updates from sessions/attempts.
- Goals drive stats and routine suggestions.
- **Mascot hook:** celebrates goal completion.
- **Data:** `TopicGoal`, `FocusSession`, `QuestionAttempt`.

## F-11 · Profile Stats (shareable)
- Dashboard: total focused hours, current/longest streak, sessions, questions solved, accuracy,
  minutes by subject, weekly/monthly trends, level/XP.
- **Shareable** as image cards (see F-12).
- **Data:** `UserStats`, all activity entities.

## F-12 · Story Layouts (shareable cards)
- Pre-designed, on-brand vertical cards (Instagram/Stories 9:16) for: daily recap, streak
  milestone, weekly stats, "I studied X hours", essay finished, question-bank accuracy.
- Pixel-art mascot featured on each card; theme-aware.
- Export/share sheet.
- **Data:** snapshot of `UserStats` / event.

## F-13 · Interactive Pixel-Art Mascot
- Central companion (à la Duo/Finch) with states: idle, focused, celebrating, sad, sleeping,
  leveling-up, cheering, studying. Sprite-sheet animation. See `05-MASCOT.md`.
- Reacts to app events (sessions, streaks, goals, blocks).
- Customizable with skins/items bought via **focus coins** (F-14).
- Lives on Home; cameo on shield screen, notifications, story cards.
- **Data:** `MascotState`, `Inventory`, `Reward`.

## F-14 · Gamification economy (XP, levels, coins)
- **XP** from focused minutes/sessions/questions → **levels** (RPG framing).
- **Focus coins** earned from completed sessions/streaks → spend on mascot skins/items/themes.
- Badges/achievements. See `07-GAMIFICATION.md`.
- **Data:** `UserStats`, `Inventory`, `Reward`, `Wallet`.

## F-15 · Co-study Rooms (opt-in social)
- Live shared focus session with friends ("estudar junto"); see who's focusing; group streak.
- Weekly ranking by focused hours (opt-in). Non-competitive mode available.
- **Data:** `Room`, `RoomMember`, `UserStats` (via CloudKit shared zones).

## F-16 · Widgets & Live Activities
- Home/Lock Screen widgets: streak, today's focus, next routine block, mascot mood.
- Live Activity for the running Pomodoro (Dynamic Island).
- **Data:** `UserStats`, `FocusSession`, `Routine`.

## F-17 · Onboarding
- Goal selection (exam/date), subjects, daily target, mascot pick + name, notifications opt-in,
  Screen Time permission (for Focus Mode), iCloud check.
- Personalized starter routine generated from answers.
- **Mascot hook:** mascot introduces itself and the app.

## F-18 · Settings & Account
- iCloud/CloudKit status, notification prefs, focus defaults, block profiles, appearance
  (light/dark, theme), data export, privacy.

---

## Feature → doc map

| Feature | Deep-dive doc |
|---------|---------------|
| F-02 Focus Mode | `06-SCREEN-TIME-FOCUS.md` |
| F-04, F-11, F-12, F-14, F-15 | `07-GAMIFICATION.md` |
| F-07, F-08, F-05/06 content | `08-CONTENT-BANKS.md` |
| F-13 Mascot | `05-MASCOT.md` |
| All data | `03-DATA-MODEL.md` |
