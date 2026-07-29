---
name: speaking-clock-lumen-redesign
description: "The \"Lumen\" UI redesign in progress for Speaking Clock — design system + migration status"
metadata: 
  node_type: memory
  type: project
  originSessionId: 168b7306-366a-4d0c-8677-81fb660ba7e7
  modified: 2026-07-29T09:46:12.878Z
---

Ongoing UI/UX redesign of **Speaking Clock**, code-named **Lumen** (horology theme: "a clock that speaks").

**Design system** (in `lib/app/app_colors.dart` + `lib/utils/ui_helpers.dart`):
- Two full palettes, theme-resolved via `AppColors.brightness`:
  - **Light** (settled with the user): warm **linen** ground (#ECE3D3), **cream** surfaces (#F6F0E3), warm near-black ink; identity accent = **olive** (#6F7E2C); intensity triad **Gentle = olive green** (#6E7E2E), **Alarm = terracotta** (#B65A3F), **Speaking = petrol/teal** (#35636E); **wine** accent (#8C4E5C) for section eyebrows; blush+lavender atmosphere behind the Today clock (lavender pinned to #C9BCE8, not the Speaking colour).
  - **Dark**: graphite ground, **brass/gold** accent, triad teal/coral/**iris** (Speaking stays iris in dark to avoid clashing with the teal Gentle).
- Reminder **cards + detail hero** are a rich per-intensity **diagonal gradient** (`lerp(base,white,.22) → base → lerp(base,black,.12)`) with a top-right sheen and **luminance-aware** text (`ThemeData.estimateBrightnessForColor` → white on deep colours, near-black on light). `_fillFor`/`_onFill` (pastel fills + deepened icon colour) are still used by Routines/Settings cards.
- Card structure: coloured fill, mono delivery label + live countdown chip, category icon (Material `_cardIcon`, deep/white, no tile) top-right, big serif title + `Category · Repeat`, huge time, ↗ open. Detail + editor share this language. Icons unified to Material `_cardIcon` (break = `self_improvement`).
- Today "+" lives on the **clock crown** (no FAB). Bottom nav is theme-aware (dark pill in dark, cream pill in light). Detail sheet is content-sized + drag-to-dismiss from anywhere.
- Typography roles via Android platform fonts: `_serif(...)` (Noto Serif, for greetings/titles/spoken lines), `_mono(...)` (Roboto Mono, for labels/units/timestamps).
- `AppColors` is now **theme-resolved getters** keyed on `AppColors.brightness` (set in `SpeakingClockApp.build` from `_darkMode`). Full **light + dark** supported. Because getters aren't const, ~54 `const` keywords were stripped app-wide (a `scratchpad/fix_const.py`-style pass drove it); keep this in mind if adding new const widgets that reference `AppColors.*` — they'll error, drop the `const`.
- `AuraPanel` was calmed to a subtle low-bloom surface (was the old glowy "AI look").

**Migrated to Lumen:** Today (live analog **dial** hero, next-up card, train-board schedule), bottom nav (clock/grid/tune, brass active, mono labels), New reminder editor (live preview + segmented intensity + 2×2 detail tiles opening picker sheets), Onboarding (dial welcome mark, teal/coral/iris intensity cards, brass permission rows), Reminder Detail / Routines / Settings (via calmed AuraPanel), native full-screen **AlarmActivity.kt** (graphite + iris/coral aura + brass mono label + serif-italic spoken line).

**Recent session polish (2026-07-29):**
- Locked the light triad above and removed the A/B demo scaffolding (`_FolderReminderCard` no longer takes an `overrideColor`; every card shows its real intensity colour).
- **Today background is now clean flat linen** — deleted `_TodayAtmosphere` (the blush/lavender/olive radial glows). Cards + clock keep their shadows to carry the eye.
- **Bottom nav floats as a true capsule**: set `Scaffold(extendBody: true)` + `SafeArea(bottom:false)` so body content scrolls continuously *behind* the padded capsule (no hard clip line at its rounded corners). Bumped all three tab scroll paddings to bottom:130 (Today/Routines/Settings) so the last item clears the floating capsule.
- **Active-tab indicator**: the current tab's icon sits in a filled `AppColors.brass` circle (olive light / gold dark) with a luminance-aware icon colour, animated via `AnimatedContainer`.
- **Reliability screen text unified** (`ReliabilityScreen` in settings_screen.dart): dropped the fuzzy `_softTextShadow` from the hero; hero + all rows now share one system — titles `AppColors.bone` w800, details `AppColors.bone` @ alpha 0.72 w500 (was the low-contrast `_subtle`/onSurfaceVariant). Hero shield icon uses `_onFill(gentle)` to match row icons.

**Still open / not done:** theme preference is NOT persisted (defaults to dark each launch — could add to `AppPreferences`); input-field fill + `_pickTime` time-picker are not fully light-mode-tuned; deeper polish per screen.

Deliverable design deck (artifact v2): https://claude.ai/code/artifact/f4f497f5-4790-465e-9e7f-a3f2e77fbaad
Build/deploy steps: [[speaking-clock-device-build]].
