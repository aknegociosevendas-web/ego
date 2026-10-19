# 06 — Focus Mode / App Blocking (Screen Time APIs)

Implementation plan for **F-02 Focus Mode**: blocking distracting apps during a focus session.

## 1. Frameworks

| Framework | Role |
|-----------|------|
| **FamilyControls** | Authorization + `FamilyActivityPicker` for the user to choose apps/categories to block. Produces a `FamilyActivitySelection` (opaque tokens). |
| **ManagedSettings** | Applies the shield: `ManagedSettingsStore().shield.applications = tokens`. Removes it when focus ends. |
| **DeviceActivity** | Schedules when blocking turns on/off; runs a `DeviceActivityMonitor` extension for start/end callbacks. |

## 2. Required entitlement (critical path)

- Blocking requires the **Family Controls** capability, which needs a **special entitlement from
  Apple** (`com.apple.developer.family-controls`) — request via the developer portal / a form.
- **Action:** apply early. Until granted, ship the **soft-focus fallback** (§7).
- Add capability in Xcode; extensions also need the entitlement + App Group for shared state.

## 3. Targets to create

1. **Main app** — requests authorization, hosts `FamilyActivityPicker`, starts/stops sessions.
2. **DeviceActivityMonitor extension** — receives `intervalDidStart` / `intervalDidEnd`; applies
   and clears the shield.
3. **ShieldConfiguration extension** — custom shield UI (EGO branding + mascot + motivational
   line) shown when a blocked app is opened.
4. **ShieldAction extension** — handles shield button taps (e.g. "voltar ao EGO", or friction
   unlock in soft mode).

All share an **App Group** so the main app and extensions read the same selection/state.

## 4. Flow

```
Onboarding/Settings
  └─ request FamilyControls authorization (.individual)
  └─ user picks apps via FamilyActivityPicker → save FamilyActivitySelection (as Data in BlockProfile)

Start focus session (F-01)
  └─ set ManagedSettingsStore.shield.applications = selection.applicationTokens
  └─ start DeviceActivity schedule for the session window

Blocked app opened
  └─ system shows ShieldConfiguration (EGO mascot + phrase)
  └─ ShieldAction handles taps (hard mode: only "close"; soft mode: confirm-to-unlock w/ friction)

Session ends / user stops
  └─ DeviceActivityMonitor.intervalDidEnd → clear shield (store.shield.applications = nil)
```

## 5. Hard vs soft mode

- **Hard mode:** no early unlock. Shield only offers "return to EGO". Strongest for exam crunch.
- **Soft mode:** unlock allowed with friction (confirmation, short delay, or spending coins/streak
  risk). Reduces frustration/uninstalls.

## 6. Known limitations (design around them)

- Tokens are **opaque** — you can't read which app it is; you only know a token was selected.
- There is **no documented API to open the parent app** directly from `ShieldActionDelegate`;
  design the shield to guide the user back manually.
- API has historically been **buggy/limited** (per developer reports) — build resilient, test on device.
- Requires **physical device** for real testing (extensions + entitlement); simulator is limited.

## 7. Soft-focus fallback (no entitlement / user declines)

- Do NOT block system-wide. Instead:
  - Strong local notifications if the user leaves EGO mid-session.
  - Suggest configuring an **iOS Focus** + a Shortcut that opens EGO.
  - "Honor mode" timer that pauses/penalizes streak if the user leaves the app.
  - Full-screen "modo foco" inside EGO with the mascot guarding.

## 8. Privacy

- Family Controls data stays on-device; selections are opaque tokens. Communicate clearly in
  onboarding why permission is requested. No app-usage data leaves the device.

## 9. Build checklist

- [ ] Apply for Family Controls entitlement (blocking is gated on this).
- [ ] Add capability + App Group to app and all 3 extensions.
- [ ] Implement authorization + picker (save selection to `BlockProfile`).
- [ ] Implement Monitor extension (apply/clear shield).
- [ ] Implement Shield UI + actions (mascot + hard/soft).
- [ ] Ship soft-focus fallback in parallel.
- [ ] Test on a real device.
