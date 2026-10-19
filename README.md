# EGO — Focus & Study App (iOS)

> Native iOS focus & study app. Pomodoro, Focus Mode (app blocking), Duolingo-style
> streaks, an interactive pixel-art mascot, study routines, a vestibular/ENEM question
> bank, essay (redação) frameworks, topic goals, and shareable stats.

**Platform:** iOS 17+ (native, Swift / SwiftUI)
**Data:** CloudKit (iCloud sync from day one) + SwiftData local cache
**UI language:** Portuguese (PT-BR) · **Docs language:** English
**Design language:** Notion-like, light & minimal
**Build workflow:** Terminal (Claude Fable 5 → later Opus) + Xcode

---

## Documentation index

| Doc | Purpose |
|-----|---------|
| [docs/00-PRD.md](docs/00-PRD.md) | Vision, goals, personas, success metrics |
| [docs/01-FEATURES.md](docs/01-FEATURES.md) | Full functional spec of every feature |
| [docs/02-ARCHITECTURE.md](docs/02-ARCHITECTURE.md) | Tech stack, modules, patterns, folder layout |
| [docs/03-DATA-MODEL.md](docs/03-DATA-MODEL.md) | CloudKit schema + SwiftData entities |
| [docs/04-DESIGN-SYSTEM.md](docs/04-DESIGN-SYSTEM.md) | Tokens, typography, spacing, components (placeholders) |
| [docs/05-MASCOT.md](docs/05-MASCOT.md) | Pixel-art mascot: concepts, states, animation system |
| [docs/06-SCREEN-TIME-FOCUS.md](docs/06-SCREEN-TIME-FOCUS.md) | App-blocking via Screen Time APIs |
| [docs/07-GAMIFICATION.md](docs/07-GAMIFICATION.md) | Streaks, XP, goals, stats, story cards |
| [docs/08-CONTENT-BANKS.md](docs/08-CONTENT-BANKS.md) | Question bank, essay frameworks, routines |
| [docs/09-ROADMAP.md](docs/09-ROADMAP.md) | Phased delivery plan & milestones |
| [docs/10-COMPETITIVE-RESEARCH.md](docs/10-COMPETITIVE-RESEARCH.md) | International benchmark + sources |
| [prompts/FABLE5-INIT-PROMPT.md](prompts/FABLE5-INIT-PROMPT.md) | Optimized kickoff prompt for coding EGO |
| [CLAUDE.md](CLAUDE.md) | Agent context file (auto-read in terminal) |

## Quick status

- [x] Competitive research (international)
- [x] Documentation set
- [ ] Mascot direction locked (see options in `05-MASCOT.md`)
- [ ] Colors & fonts locked (placeholders in `04-DESIGN-SYSTEM.md`)
- [ ] Xcode project scaffolded
- [ ] Feature build (see `09-ROADMAP.md`)

## Open decisions

1. **Mascot** — pick one concept in `docs/05-MASCOT.md` (pixel-art).
2. **Palette & fonts** — replace placeholders in `docs/04-DESIGN-SYSTEM.md`.
3. **Question-bank sourcing** — licensing/format for vestibular content (`docs/08-CONTENT-BANKS.md`).
