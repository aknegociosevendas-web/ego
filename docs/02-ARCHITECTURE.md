# 02 — Architecture

## 1. Stack

- **Language:** Swift 5.9+
- **UI:** SwiftUI (iOS 17+), UIKit only where required (Live Activities, some shields).
- **Persistence:** **SwiftData** (local source of truth) + **CloudKit** sync (private DB) from day one.
- **Concurrency:** Swift Concurrency (async/await, actors).
- **Focus Mode:** FamilyControls, ManagedSettings, DeviceActivity (+ extension targets).
- **Widgets / Live Activities:** WidgetKit + ActivityKit + App Intents.
- **Notifications:** UserNotifications (local) + optional push later.
- **Animation:** SwiftUI + sprite-sheet driver for the pixel-art mascot (see `05-MASCOT.md`).
- **Min deployment:** iOS 17.0.

## 2. Pattern

**MVVM + lightweight feature modules.** Each feature is a self-contained folder with its own
Views, ViewModels, and Models references. Shared services live in `Core`. Views are dumb;
ViewModels own state (`@Observable`); services own side effects and persistence.

```
View  ──>  ViewModel (@Observable)  ──>  Service/Repository  ──>  SwiftData/CloudKit
              ▲                                   │
              └──────────── domain models ────────┘
```

Rules:
- No business logic in Views.
- ViewModels never import SwiftData directly — they talk to repositories.
- Repositories are protocol-based (`FocusRepository`, `StreakRepository`, …) for testability.
- One-way data flow; state changes go through the ViewModel.

## 3. Module map (target folder layout in Xcode)

```
EGO/
  App/
    EGOApp.swift                 // @main, DI container, ModelContainer
    AppRouter.swift              // tab / navigation root
    DIContainer.swift            // service registration
  Core/
    Persistence/                 // ModelContainer, CloudKit config, migrations
    Services/                    // FocusService, StreakService, NotificationService, ...
    DesignSystem/                // tokens, colors, typography, components (see 04)
    Extensions/
    Utilities/
  Features/
    Focus/                       // F-01 Pomodoro, F-16 Live Activity
    FocusMode/                   // F-02 app blocking (+ extensions)
    Streak/                      // F-04
    Routines/                    // F-05, F-06
    QuestionBank/                // F-07
    Essays/                      // F-08
    Reminders/                   // F-03, F-09
    Goals/                       // F-10
    Stats/                       // F-11, F-12 story cards
    Mascot/                      // F-13 sprite engine + states
    Gamification/                // F-14 XP/coins/badges
    Social/                      // F-15 co-study rooms
    Onboarding/                  // F-17
    Settings/                    // F-18
  Extensions/
    ShieldConfiguration/         // Focus Mode shield UI
    ShieldAction/                // Focus Mode shield actions
    DeviceActivityMonitor/       // schedule callbacks
    Widgets/                     // WidgetKit + Live Activity
  Resources/
    Assets.xcassets              // colors, mascot sprite sheets, story templates
    Localizable (PT-BR)          // app copy
  Tests/
    UnitTests/                   // services, repositories, gamification math
    UITests/
```

## 4. Dependency injection

Constructor injection via a small `DIContainer`. Services registered at app launch; ViewModels
receive their dependencies. Enables swapping real repositories for mocks in tests/previews.

## 5. Persistence & sync strategy

- **SwiftData** models mirror the domain entities in `03-DATA-MODEL.md`.
- Enable **CloudKit** on the `ModelContainer` (`ModelConfiguration(..., cloudKitDatabase: .private)`).
  Requires: iCloud capability, CloudKit container, background modes (remote notifications).
- CloudKit constraints to respect in the schema: all non-optional attributes need defaults or must
  be optional; no unique constraints; relationships must be optional. Design entities accordingly.
- **Shared zones** (CKShare) power co-study rooms (F-15) — later phase.
- Conflict policy: last-writer-wins for stats counters; append-only logs for history (F-06).

## 6. Background & extensions

- Pomodoro continues via Live Activity + local notifications (no illegal background exec).
- Focus Mode blocking runs through DeviceActivity schedules + ManagedSettings store (system-driven).
- Widgets/Live Activities read from a shared App Group container for cheap state.

## 7. Third-party dependencies

Keep to near-zero. Prefer first-party frameworks. If needed later: a lightweight sprite/animation
helper and a charts lib (or Swift Charts, first-party). Add via Swift Package Manager only.

## 8. Testing

- Unit test gamification math (XP, coins, streak transitions), repositories (in-memory ModelContainer),
  spaced-repetition scheduling (SM-2).
- Snapshot/preview-driven UI checks for key screens and story cards.
- CI target: `xcodebuild test` on the shared scheme.

## 9. Build & tooling

- **Xcode** project (or Tuist/XcodeGen later if generation helps).
- Coding done in terminal with Claude (Fable 5 → Opus) + Xcode for builds/simulator.
- SwiftLint + SwiftFormat recommended for consistency.
- Conventional commits; one feature module per PR where possible.
