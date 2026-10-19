# 10 — Competitive Research (International Benchmark)

Research pass focused on international ("gringa") study/focus apps to validate EGO's
feature list and surface additional proven mechanics. Summary of findings + what EGO
should adopt, adapt, or skip.

## Benchmarked apps

| App | Core idea | Standout mechanic | Why it matters for EGO |
|-----|-----------|-------------------|------------------------|
| **Forest** | Plant a tree while you focus; abandon = tree dies | Loss-aversion timer + real tree planting; "Plant Together" group rooms (15M+ downloads, 5M+ real trees) | Validates loss-aversion focus timer + social/group focus |
| **Duolingo** | Gamified learning | Mascot "Duo" + streaks + leaderboards drove churn from 47%→28% and +36% YoY DAU | Validates mascot + streak + high-frequency triggers as retention engine |
| **Finch** | Self-care pet that grows from your actions | Affection over competition; +56% retention vs peers, 2.34M downloads/90 days | Validates a caring, non-punitive mascot narrative |
| **Study Bunny** | Cartoon bunny cheering study | Coins from focus → buy items for the pet | Validates pet customization economy for students |
| **Focus To-Do** | Pomodoro + tasks | Sessions tied directly to to-dos | Validates linking focus sessions to study tasks/goals |
| **Focus Quest** | Pomodoro RPG for ADHD | Focus as an RPG progression | Validates XP/leveling framing of focus |
| **Anki** | Spaced repetition (SM-2) | Gold standard SRS for memorization | Validates optional spaced-repetition layer for the question bank |
| **Routinery / Habi** | Routine & habit tracking | Structured routines, streaks | Validates study-routine builder |

## Validated additions to EGO's original list

Features not in the original brief that international benchmarks prove are worth adding:

1. **Loss-aversion focus visual** — a mascot/scene that visibly "suffers" or resets if
   you quit a session early (Forest's dying tree, Finch's pet). Stronger than a neutral timer.
2. **Group / co-study focus rooms ("Plant Together")** — shared live sessions with friends;
   major driver of accountability and word-of-mouth. Great fit with shareable stats + streaks.
3. **Focus-coin economy → mascot customization** — earn coins from completed sessions, spend
   on mascot skins/items (Study Bunny, Forest). Directly reinforces the pixel-art mascot.
4. **Spaced repetition (SM-2) layer** — optional review scheduling on top of the question bank
   and essay/flashcards (Anki). High value for vestibular/ENEM memorization.
5. **XP + levels ("RPG" framing)** — turn focus minutes into a progression curve (Focus Quest).
6. **Leaderboards / weekly ranking by hours** — opt-in competitive layer among friends.
7. **Streak freeze / repair** — Duolingo's streak-saver reduces rage-quit churn when a streak breaks.
8. **Widgets + Live Activities + Lock Screen** — keep the timer and streak visible outside the app
   (strong iOS-native retention lever).
9. **"Sessions tied to tasks/goals"** — every Pomodoro can be attached to a topic goal, so time
   auto-attributes to the right subject in stats.

## What to be cautious about

- **App blocking (Focus Mode)** requires Apple's **Family Controls entitlement** (special approval).
  The Screen Time API has known UX limits (e.g. re-opening the parent app to unlock). Plan around it.
  See `06-SCREEN-TIME-FOCUS.md`.
- **Question-bank content** (past vestibular/ENEM exams) has **licensing/attribution** implications.
  ENEM items are public (INEP), but many vestibular banks are copyrighted. Confirm sourcing.
- **Leaderboards can hurt** intrinsic motivation for some users — keep social layers **opt-in**
  and offer a Finch-style non-competitive mode.

## Mascot insight

The two most retention-effective mascots studied (Duo, Finch) share three traits EGO should copy:
1. **Personality with stakes** — the mascot reacts emotionally to your behavior (proud, worried, sad).
2. **Growth tied to real actions** — it visibly evolves as you study, not on a random timer.
3. **A narrative reason to return** — "your buddy needs you today" (soft nudge, not pure guilt).

EGO adds a differentiator: **pixel-art art direction**, which is cheap to animate (sprite sheets),
nostalgic, highly shareable in story cards, and easy to theme/skin for the coin economy.

## Sources

- [Best Pomodoro Apps 2026 — Routinery](https://www.routinery.app/blog/best-pomodoro-apps)
- [Best Pomodoro Apps 2026 — The Blog Timer](https://theblogtimer.com/guides/best-pomodoro-apps)
- [7 Best Focus Timer Apps 2026 — Habi](https://habi.app/insights/best-focus-timer-apps/)
- [Top 11 Pomodoro Timer Apps 2026 — Reclaim](https://reclaim.ai/blog/best-pomodoro-timer-apps)
- [Best Student Productivity Apps 2026 — Academync](https://academync.com/articles/integratedstudyproductivityappshabitsfocuspomodoro)
- [Focus Quest — Google Play](https://play.google.com/store/apps/details?id=com.shikudo.focus.study.forest.pomodoro.productivity.hero.rpg.android&hl=en_US)
- [Duolingo gamification — StriveCloud](https://www.strivecloud.io/blog/gamification-examples-boost-user-retention-duolingo)
- [Duolingo case study 2026 — Ludaxis](https://www.ludaxis.io/blog/gamification-in-apps-duolingo-case-study-2026)
- [Gamification: Duolingo, Strava, Forest — CitrusBits](https://citrusbits.com/how-gamification-has-catapulted-duolingo-strava-and-forest-to-the-top-of-their-respective-app-categories/)
- [New Horizons in Habit-Building Gamification — Naavik](https://naavik.co/deep-dives/deep-dives-new-horizons-in-gamification/)
- [Developer's Guide to Apple Screen Time APIs — Medium](https://medium.com/@juliusbrussee/a-developers-guide-to-apple-s-screen-time-apis-familycontrols-managedsettings-deviceactivity-e660147367d7)
- [iOS App Blocker with Screen Time APIs — Medium](https://medium.com/@jc_builds/building-a-powerful-ios-app-blocker-with-screen-time-apis-the-complete-guide-f6272bd00fc4)
- [Screen Time Technology Frameworks — Apple Developer](https://developer.apple.com/documentation/screentimeapidocumentation)
- [Configuring Family Controls — Apple Developer](https://developer.apple.com/documentation/xcode/configuring-family-controls)
- [Best Study Tracker Apps — Viasocket](https://viasocket.com/discovery/blog/grdoz1/productivity-apps/8-best-study-tracker-apps-for-consistency)
- [Best Study Planner Apps 2026 — Revu](https://revu.co.in/tools/best-study-planner-apps)
- [Best Spaced Repetition App 2026 — NoteLyn](https://www.notelyn.com/blog/spaced-repetition-app)
