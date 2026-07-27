# Speaking Clock — Project Context

> A single-file, engineering-focused snapshot of what this app **is**, what is **actually implemented** (with an emphasis on the native Android layer), and how the pieces fit together. Written to be the fast on-ramp for anyone (human or agent) picking the project up cold.

---

## 1. What the app is

**Speaking Clock** is a *calm reminder companion* for hydration, breaks, medication, and meetings. Its differentiator is not "another to-do app" — it is **reliability**: reminders that actually fire, even when the phone is locked, in Do Not Disturb, rebooted, or the app has been swiped away. It reaches the user through three escalating **intensities**:

| Intensity | Behavior | Aura (current) |
|-----------|----------|----------------|
| **Gentle Reminder** | A light heads-up notification with `Done` / `Remind again` actions. No takeover. | Lime |
| **Alarm Reminder** | Full-screen lock-screen alarm + looping alarm tone until acknowledged. | Coral |
| **Speaking Alarm** | Speaks a custom message via TTS, then rings until acknowledged. | Magenta |

Emotional core: *"Speaking Clock helps you remember important things when work pulls you too deep."*

**Stack:** Flutter (Dart) UI + a substantial **native Android (Kotlin)** alarm engine bridged over a `MethodChannel`. Local persistence via **drift/SQLite**. iOS/desktop targets exist as Flutter scaffolding but the reliability engine is Android-only today.

**Current status:** Android Phase 1 (alarm foundation) and the main Phase 2 (real-world reliability) are **complete and verified on a physical Pixel 8**. The team is deep in **Phase 3 (UX polish)** — the visual system has already been migrated to a dark-first "Aura on Ink" language. Phase 4 (calendar integrations) and Phase 5 (iOS) are future.

---

## 2. Repository map

```
lib/
  main.dart                         # entrypoint; declares all `part` files (single-library architecture)
  app/
    app_colors.dart                 # design tokens: Aura-on-Ink palette + gradients
    speaking_clock_app.dart         # root widget: theme, nav shell, reminder CRUD orchestration, alarm scheduling glue
  models/
    reminder.dart                   # Reminder, ReminderDraft, enums (ReminderType/DeliveryMode/ToneOption)
  data/
    app_database.dart               # drift DB (ReminderRecords table) + queries
    app_database.g.dart             # generated drift code
    app_preferences.dart            # shared_preferences (onboarding-complete flag)
  platform/
    reliability_platform.dart       # Dart side of the MethodChannel bridge + AlarmReadiness model
  screens/
    onboarding/onboarding_screen.dart
    today/today_screen.dart
    routines/routines_screen.dart
    settings/settings_screen.dart
    reminder_detail/reminder_detail_screen.dart
    reminder_editor/reminder_editor.dart
  utils/ui_helpers.dart             # SoftPanel/GlassPanel/AuraPanel primitives, aura specs, formatters, labels
  widgets/custom_icons.dart         # hand-painted category icons (droplet, bell, speaker, pill, etc.)

android/app/src/main/kotlin/com/example/speaking_clock/
  MainActivity.kt                   # MethodChannel handler + AlarmReadiness (permission/status checks)
  AlarmScheduler.kt                 # schedules/cancels exact alarms via AlarmManager.setAlarmClock
  AlarmReceiver.kt                  # BroadcastReceiver: fires alarm, handles recurrence + gentle actions
  AlarmPlaybackService.kt           # foreground service: TTS speech + looping alarm tone
  AlarmActivity.kt                  # native full-screen lock-screen alarm UI (hand-built views)
  AlarmNotificationHelper.kt        # notification channels + reliable/gentle notifications
  ScheduledAlarmStore.kt            # SharedPreferences persistence + recurrence math
  BootReceiver.kt                   # restores alarms after reboot / app update

docs/speaking-clock-roadmap.md      # detailed phase-by-phase roadmap + verified-on-Pixel test log
```

**Architectural note:** `lib/` is a *single Dart library*. `main.dart` uses `part`/`part of` for every screen and model, so all private helpers (`_repeatRule`, `_deliveryLabel`, `AppColors`, etc.) are shared library-wide. Only `data/`, `platform/` are true imported libraries. The roadmap flags gradual conversion of `part` files into real imports as future cleanup.

---

## 3. The native Android engine (the important part)

This is where the product's real value lives. The Flutter side is essentially a control panel; **Android does the reliable firing.**

### 3.1 MethodChannel bridge — `speaking_clock/reliability`
Handled in `MainActivity.kt`. Methods:

| Method | Purpose |
|--------|---------|
| `getStatus` | Returns readiness map: `notificationsEnabled`, `exactAlarmEnabled`, `dndPolicyAccess`, `alarmVolumeEnabled`, `fullScreenIntentEnabled`. |
| `requestNotifications` | Requests `POST_NOTIFICATIONS` (Android 13+). |
| `requestExactAlarms` | Opens `ACTION_REQUEST_SCHEDULE_EXACT_ALARM` (Android 12+). |
| `openDndSettings` | Opens the **Reliable alarms notification-channel** settings (fallback chain → app notif settings → notification policy access). |
| `openFullScreenIntentSettings` | Opens full-screen-intent settings (Android 14+) or app notif settings. |
| `scheduleAlarm` | Validates exact-alarm + alarm-volume readiness, then schedules. |
| `cancelAlarm` | Cancels a scheduled alarm by id. |

### 3.2 Scheduling — `AlarmScheduler.kt`
- Uses `AlarmManager.setAlarmClock(AlarmClockInfo, PendingIntent)` — the **highest-priority** exact-alarm API; survives Doze, shows a system alarm indicator, and is allowed to be exact without special power exemptions.
- Alarm id = `reminder.id.hashCode() & 0x7fffffff` (stable per reminder).
- Every schedule is **persisted** to `ScheduledAlarmStore` so it can be restored after reboot.

### 3.3 Firing — `AlarmReceiver.kt`
On `FIRE_ALARM`:
1. **Reschedules the next occurrence first** (via `ScheduledAlarmStore.nextTriggerAfter`) so recurrence survives even if downstream work fails; if no next occurrence, removes from store.
2. **Gentle** → posts a gentle notification (`Done` / `Remind again`) and returns.
3. **Alarm/Speaking** → starts `AlarmPlaybackService` (foreground) **and** launches `AlarmActivity` full-screen.

Also handles `GENTLE_DONE` (cancel notification) and `GENTLE_SNOOZE` (lightweight reschedule, no full-screen).

### 3.4 Playback — `AlarmPlaybackService.kt`
- Foreground service (`mediaPlayback` type) so audio survives app death.
- **Speaking Alarm:** `TextToSpeech` with `USAGE_ALARM` audio attributes speaks the message → 2s gap → alarm tone.
- **Alarm Reminder:** looping `Ringtone` with `USAGE_ALARM`.
- Tone map: `softChime`/`calmWater` → notification tone; others → alarm tone; `vibrationOnly` → silent.
- Handles `STOP_ALARM` (acknowledge) and `SNOOZE_ALARM` (reschedule +N min) intents from the notification.

### 3.5 Full-screen UI — `AlarmActivity.kt`
- Shown over the lock screen (`setShowWhenLocked` / `setTurnScreenOn` / `FLAG_KEEP_SCREEN_ON`).
- **UI is built entirely in Kotlin with hand-constructed views** (no XML, no Flutter) — a radial "aura" gradient background (coral for alarm, magenta for speaking), a glass icon bubble, big current time, mode pill, title (+ spoken message), `Acknowledge` (solid) / `Snooze` (glass) buttons.
- Warns inline if alarm volume is muted/too low.
- Uses density-independent `dp()` sizing (a past bug: raw pixels made buttons look like thin bars on Pixel density).

### 3.6 Notifications — `AlarmNotificationHelper.kt`
- Two channels: `reliable_alarms_v4` (IMPORTANCE_HIGH, sound null so the **service** owns audio, vibration pattern, `setBypassDnd` when policy granted) and `gentle_reminders`.
- Reliable notification: `CATEGORY_ALARM`, `setFullScreenIntent(..., true)`, ongoing, `Acknowledge` + `Snooze N min` actions. This is the heads-up path when another app is foregrounded.

### 3.7 Recurrence — `ScheduledAlarmStore.kt`
- Persists all scheduled alarms as JSON in SharedPreferences (`speaking_clock_scheduled_alarms`).
- `nextTriggerAfter` understands: `Every day` (+1 day), `Weekdays` (skip Sat/Sun), and **custom minutes** (`Every N min` regex), else `null` (one-shot).
- **Custom-minute semantics (important, previously buggy):** the *first* fire stays at the user-selected AM/PM time; it then repeats every N minutes. It is *not* "N minutes from now."

### 3.8 Reboot / update recovery — `BootReceiver.kt`
- Listens for `BOOT_COMPLETED` + `MY_PACKAGE_REPLACED`.
- Walks the persisted store, advances each alarm's trigger to the next future occurrence, and reschedules. **Verified on Pixel 8.**

### 3.9 Manifest permissions
`POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`, `ACCESS_NOTIFICATION_POLICY`, `USE_FULL_SCREEN_INTENT`, `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_MEDIA_PLAYBACK`, `RECEIVE_BOOT_COMPLETED`, `WAKE_LOCK`.

### 3.10 Readiness model (the reliability contract)
`AlarmReadiness` (Dart mirror of the native status). Derived gates:
- `canScheduleGentleReminders` = notifications + exact alarms
- `canScheduleReliableAlarms` = notifications + exact alarms + **alarm volume audible**
- `isReady` = all five signals green

Two hard-won reliability lessons baked into the checks:
- **DND readiness** is read from the *Reliable alarms channel's* `canBypassDnd()`, **not** broad Modes access — the channel can be blocked even when Modes access is on.
- **Alarm volume** must be strictly **above `getStreamMinVolume`** — Pixel reports the bottom slider position as a non-zero volume, which is not loud enough to trust for spoken alarms.

---

## 4. Data & domain model

`Reminder` (`lib/models/reminder.dart`):
- `id, title, time (label), detail, type, deliveryMode, spokenMessage, tone, enabled, snoozeMinutes, triggerAtMillis, created/updatedAtMillis`
- `isAlarm` = mode != gentle; `isSpeakingAlarm` = mode == speaking.
- `detail`'s first ` · `-segment doubles as the repeat rule (`_repeatRule` parses it) — a slight overload worth knowing.

Enums:
- `ReminderType`: `water, breakTime, meeting, medication, custom`
- `DeliveryMode`: `gentle, alarm, speaking`
- `ToneOption`: `softChime, classicAlarm, digitalBeep, morningBell, calmWater, vibrationOnly`

Editor options:
- **Repeat:** `Once`, `Every day`, `Weekdays`, `Custom minutes` (→ `Every N min`, clamped 1–1440)
- **Snooze / remind-again:** 2 / 5 / 10 / 15 / 30 min
- **Time:** 12-hour AM/PM picker with a Today/Tomorrow preview

Persistence: `ReminderRecords` drift table (schemaVersion 1). In-memory seed reminders are written on first run if the DB is empty.

---

## 5. Flutter UI layer (current "Aura on Ink" system)

- **Navigation:** `IndexedStack` over three tabs — **Today**, **Routines**, **Settings** — with a custom frosted `_AuraBottomNav` and an extended "Add reminder" FAB.
- **Design tokens** (`app_colors.dart`): `ink #0a0a0a`, `surface #121212`, `surfaceRaised #1a1a1a`, `bone #fff`, `boneDim`, hairline `line`, `glass`; auras `magenta #e85a9b`, `blue #5a82e8`, `coral #e88c78`, `lime #a8e87a`; `destructive #d97757`. Legacy warm-palette aliases (linen/wine/sage) are retained but remapped onto the dark tokens for migration safety.
- **UI primitives** (`ui_helpers.dart`): `SoftPanel` (regular cards), `GlassPanel` (blur cards), `AuraPanel` (hero surfaces with layered radial gradients + a `_NoisePainter` grain). `AuraHue` maps delivery mode → signature light.
- **Theme:** dark-first Material 3, white primary buttons on ink, `Work Sans` font family, custom nav/input/snackbar theming.
- **Screens:** Today (greeting header, "Next up" aura hero, "Later today" schedule list, reliability warnings), Routines (6 quick-start templates that pre-fill the editor), Settings (control-center with reliability readiness card + Phase-4 integration placeholders), Reminder Detail (gradient hero + Edit/Delete), Reminder Editor (bottom sheet), Onboarding (4-step gradient flow ending in a per-permission readiness checklist).

---

## 6. Verification workflow (team convention)

After each meaningful change the team runs:
```sh
dart format lib test
flutter analyze
flutter test
```
plus an **Android debug APK build** and a **Pixel 8 install + launch** when the device is connected. The roadmap keeps a detailed "verified on Pixel 8" log (locked screen, DND, alarm-volume edge cases, app-killed, other-app-foreground, reboot, snooze, custom recurrence, multi-alarm overlap, soak test, permission-revoked). Treat these as the reliability regression suite — **UI work must not break them.**

---

## 7. Known constraints / gotchas for future work

- `lib/` is one big `part`-linked library; adding a screen means adding a `part`/`part of` pairing in `main.dart`.
- `detail` string encodes both human copy and the repeat rule — don't reformat it blindly.
- Alarm ids are derived from `id.hashCode` — collisions are theoretically possible; keep ids distinct.
- The native `AlarmActivity` UI is hand-coded Kotlin views, **not** Flutter — any full-screen alarm redesign happens in Kotlin and must not touch scheduling/playback.
- iOS cannot replicate Android's full-screen-alarm behavior; Phase 5 must design within iOS limits rather than fake parity.
- Reliability is the product. Any redesign must preserve the readiness gates, permission flows, and the Pixel-verified firing paths.
