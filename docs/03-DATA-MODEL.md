# 03 — Data Model (SwiftData + CloudKit)

Domain entities backing the features. Designed to satisfy CloudKit-with-SwiftData constraints:
**all attributes optional or defaulted, all relationships optional, no unique constraints, and
every relationship MUST declare its inverse via `@Relationship(inverse:)`.**
Types are indicative Swift types.

> ⚠️ **Inverse relationships are mandatory.** CloudKit rejects a relationship without an inverse and
> the real (non–in-memory) store fails to load — this caused an intermittent launch/test crash in
> Phase 1. Any one-to-many must be declared on both sides (e.g. `UserStats.subjectStats: [SubjectStat]?`
> with `@Relationship(inverse: \SubjectStat.stats)`). In-memory test stores can hide this; always run
> at least one test against a real `ModelContainer` with the full schema.

> Convention: every entity has `id: UUID`, `createdAt: Date`, `updatedAt: Date`.

## User & stats

### `UserProfile`
`displayName: String?`, `examTarget: String?` (e.g. "ENEM 2026"), `examDate: Date?`,
`dailyGoalMinutes: Int = 25`, `mascotId: String?`, `mascotName: String?`, `xp: Int = 0`,
`level: Int = 1`, `coins: Int = 0`, `appearanceTheme: String?`.

### `UserStats`
Aggregated counters (denormalized for fast dashboards):
`totalFocusMinutes: Int = 0`, `totalSessions: Int = 0`, `questionsSolved: Int = 0`,
`questionsCorrect: Int = 0`, `essaysFinished: Int = 0`, `currentStreak: Int = 0`,
`longestStreak: Int = 0`, `lastActiveDay: Date?`. Per-subject rollups stored in `SubjectStat`.

### `SubjectStat`
`subject: String?`, `focusMinutes: Int = 0`, `questionsSolved: Int = 0`,
`questionsCorrect: Int = 0`, relationship → `UserStats?`.

## Focus

### `FocusSession`
`startedAt: Date?`, `endedAt: Date?`, `plannedMinutes: Int = 25`, `actualMinutes: Int = 0`,
`type: String = "focus"` (focus/short/long), `completed: Bool = false`,
`abandoned: Bool = false`, `subject: String?`, relationship → `TopicGoal?`, `Routine?`.

### `BlockProfile`
`name: String?`, `tokensData: Data?` (serialized FamilyActivitySelection),
`hardMode: Bool = false`. One or more per user; selected per focus session.

## Streak & gamification

### `Streak`
`current: Int = 0`, `longest: Int = 0`, `lastQualifiedDay: Date?`, `freezesAvailable: Int = 0`,
`freezeUsedDates: [Date]?`.

### `Reward` / `Badge`
`key: String?`, `title: String?`, `unlockedAt: Date?`, `type: String?` (badge/skin/theme/card).

### `Wallet`  *(or fold coins into UserProfile)*
`coins: Int = 0`, ledger via `CoinTransaction` (`amount: Int`, `reason: String?`, `date: Date?`).

### `Inventory` / `InventoryItem`
`itemKey: String?`, `category: String?` (skin/accessory/theme), `equipped: Bool = false`.

## Routines

### `Routine`
`name: String?`, `templateKey: String?`, `startDate: Date?`, `active: Bool = true`,
relationship → `[RoutineBlock]`.

### `RoutineBlock`
`weekday: Int?` (1–7), `subject: String?`, `targetMinutes: Int = 0`,
`targetSessions: Int = 0`, `order: Int = 0`, relationship → `Routine?`.

### `RoutineLog`  *(feeds 6-month history, append-only)*
`date: Date?`, `subject: String?`, `plannedMinutes: Int = 0`, `completedMinutes: Int = 0`,
`completed: Bool = false`, relationship → `RoutineBlock?`.

## Goals

### `TopicGoal`
`subject: String?`, `topic: String?`, `targetHours: Double?`, `targetQuestions: Int?`,
`targetEssays: Int?`, `deadline: Date?`, `progressMinutes: Int = 0`,
`progressQuestions: Int = 0`, `completed: Bool = false`.

## Question bank (F-07)

### `Question`
`externalId: String?`, `exam: String?`, `year: Int?`, `subject: String?`, `topic: String?`,
`difficulty: Int?`, `statement: String?`, `optionsData: Data?` (choices),
`correctIndex: Int?`, `explanation: String?`, `source: String?`, `licenseNote: String?`.
(Content bundled/synced — see `08-CONTENT-BANKS.md`.)

### `QuestionAttempt`
`chosenIndex: Int?`, `correct: Bool = false`, `answeredAt: Date?`, `timeSpent: Int = 0`,
`markedForReview: Bool = false`, relationship → `Question?`.

### `ReviewItem` (SM-2 spaced repetition)
`easeFactor: Double = 2.5`, `interval: Int = 0`, `repetitions: Int = 0`, `dueDate: Date?`,
`lastGrade: Int?`, relationship → `Question?` (or `EssayFlashcard?`).

## Essays (F-08)

### `EssayTemplate`
`key: String?`, `title: String?`, `structureData: Data?` (sections), `rubricKey: String?`.

### `EssayDraft`
`title: String?`, `bodyText: String?`, `wordCount: Int = 0`, `selfScore: Int?`,
`competencyScoresData: Data?`, `finishedAt: Date?`, relationship → `EssayTemplate?`.

### `EssayFlashcard` (repertório)
`front: String?`, `back: String?`, `theme: String?` (for SM-2 via `ReviewItem`).

## Reminders & notifications

### `Reminder`
`title: String?`, `body: String?`, `time: Date?`, `weekdays: [Int]?`, `subject: String?`,
`type: String?` (routine/streak/custom), `enabled: Bool = true`.

### `NotificationTemplate`
`key: String?`, `phrase: String?`, `category: String?` (streak/comeback/milestone/generic).

## Social (F-15, later phase — CKShare)

### `Room`
`name: String?`, `ownerId: String?`, `weeklyRanking: Bool = false`, relationship → `[RoomMember]`.

### `RoomMember`
`userId: String?`, `displayName: String?`, `weekMinutes: Int = 0`, `currentStreak: Int = 0`.

## Mascot (F-13)

### `MascotState` *(usually derived at runtime, persisted for sync of choice/mood)*
`mascotId: String?`, `name: String?`, `currentMood: String?`, `level: Int = 1`,
`equippedSkin: String?`.

---

## Notes for implementation

- Prefer **denormalized counters** in `UserStats`/`SubjectStat` updated transactionally when a
  `FocusSession`/`QuestionAttempt`/`EssayDraft` completes — keeps dashboards O(1).
- Keep **append-only logs** (`RoutineLog`, `CoinTransaction`, `QuestionAttempt`) for history/trends
  and to survive CloudKit merge conflicts.
- Serialize complex value types (choices, structure, competency scores, FamilyActivitySelection)
  as `Data?` to stay CloudKit-friendly.
