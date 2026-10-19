# 07 — Gamification System

Covers F-04 (streak), F-11 (stats), F-12 (story cards), F-14 (XP/coins/levels), F-15 (social).
Design goal: reproduce Duolingo/Finch/Forest retention mechanics **without punishing** the user
into churn. All competitive layers are **opt-in**.

## 1. The core loop

```
Study (focus session / question / essay)
   → earn XP + coins + progress streak
   → mascot reacts + stats update
   → milestones unlock rewards (skins, badges, story cards)
   → notification/story pulls user back tomorrow
```

## 2. XP & levels (RPG framing)

- XP sources (tunable): focus minute = 1 XP; completed session = +10; question correct = +3;
  essay finished = +50; goal completed = +40; streak milestone = bonus.
- Level curve: `xpForLevel(n) = 50 * n * (n + 1)` (super-linear, so early levels feel fast).
- Level-ups trigger a **mascot level-up animation** + a reward.

## 3. Focus coins (economy)

- Earn coins from **completed** sessions/streak milestones/goals (not from abandoned sessions).
- Spend on: **mascot skins/accessories**, **UI themes**, **streak freezes**.
- Ledger via `CoinTransaction` (append-only) → `Wallet`/`UserProfile.coins`.
- Guard against grinding: cap coins/day; abandoned sessions earn nothing (loss aversion).

## 4. Streak system (F-04)

- A day **qualifies** when the user meets `dailyGoalMinutes` (or ≥1 completed focus session).
- `current` increments once/day on first qualifying event; resets if a day is missed.
- **Streak freeze:** consumes a freeze to protect one missed day (earned/limited/buyable with coins).
- **Streak repair:** optional one-tap restore within 24–48h (limited) — reduces rage-quit churn.
- Milestones: 3, 7, 14, 30, 60, 100, 180, 365 → badges, skins, special story cards.
- Mascot mood scales with streak; "worried" state when streak is at risk near end of day → nudge.

## 5. Badges & achievements (`Reward`)

Examples: "Primeira sessão", "7 dias seguidos", "100 questões", "Redação nota 1000 (self-score)",
"Madrugador" (study before 7am), "Maratona" (≥3h in a day), "Foco de aço" (finish a hard-mode block).

## 6. Stats (F-11)

Dashboard tiles: total focused hours, current/longest streak, sessions, questions solved &
accuracy, essays finished, level & XP bar, minutes by subject, weekly/monthly trend chart,
best day/time. All computed from denormalized `UserStats`/`SubjectStat` for speed.

## 7. Story cards (F-12)

On-brand 9:16 shareable images, pixel-art mascot featured, theme-aware. Templates:
- Daily recap ("Hoje: 2h15 de foco 🔥")
- Streak milestone ("30 dias sem falhar!")
- Weekly stats summary
- Subject breakdown
- Essay finished / question accuracy
- Level-up card
Rendered via SwiftUI → `ImageRenderer` → share sheet.

## 8. Social (F-15, opt-in)

- **Co-study rooms:** live "estudar junto"; see who's focusing now; shared group streak.
- **Weekly ranking** by focused hours among friends/room — **opt-in**, with a **non-competitive
  mode** (Finch-style: no leaderboard, just mutual encouragement).
- Built on CloudKit shared zones (CKShare) — Phase 4.

## 9. Anti-patterns to avoid

- Don't guilt-trip destructively; keep nudges caring (research: Finch's affection model retains better).
- Don't make streaks so punishing that a single miss makes users quit → that's why freeze/repair exist.
- Keep competition optional; some students are demotivated by leaderboards.
- Don't let coins/XP overshadow real study — reward outcomes (finished sessions, correct answers), not mere presence.

## 10. Tunable constants (single source)

Keep all rates/curves in one `GamificationConfig` so balancing doesn't require code archaeology.
Unit-test the math (XP curve, coin caps, streak transitions, freeze logic).
