# Speaking Clock — Current Standing and Roadmap

## Current standing

Android Phase 1 core alarm engine is working on the physical Pixel 8, and the main Android Phase 2 reliability pass is now verified under real-world conditions.

What is working now:

- The app runs on Android.
- The user can create reminders.
- The app supports three reminder behaviors:
  - Gentle Reminder
  - Alarm Reminder
  - Speaking Alarm
- Alarm Reminder opens the full-screen alarm screen.
- Speaking Alarm opens the full-screen alarm screen.
- Acknowledge stops the alarm.
- Snooze works and fires again after the snooze time.
- Custom spoken text works.
- Built-in tone selection exists.
- Reliable Alarm permission setup screen exists.
- Notifications, exact alarms, alarm volume, Do Not Disturb, and full-screen alarm checks are part of the flow.
- Pixel 8 real-device testing confirmed the important full-screen alarm path.
- First-run onboarding exists for permission setup and reminder-mode education.
- 12-hour AM/PM reminder time selection is supported.
- The editor warns whether the selected reminder will fire Today or Tomorrow.
- Custom-minute recurrence is supported, such as every 2 minutes, 25 minutes, or 90 minutes.
- Native Android recurrence understands custom rules like `Every 2 min`.
- The native lock-screen alarm screen has been restyled to match the app's calm cream/sage design language.
- Alarm title display on the lock-screen alarm screen is now plain typography rather than a raised card.
- Native schedule logging was added for easier debugging.
- Android boot/update recovery scaffolding exists through a boot/package-replaced receiver and native scheduled-alarm persistence.
- Actual Pixel 8 reboot recovery test passed: an alarm scheduled before restart restored and fired after restart.
- DND readiness now checks the actual `Reliable alarms` notification channel DND interruption state, not only broad Android Modes access.
- The DND setup action now opens the `Reliable alarms` notification channel settings instead of the broad Modes access page.
- Alarm volume readiness now treats Pixel/Android's bottom alarm volume level as unsafe, even when Android technically reports a non-zero stream volume.
- Today screen permission warnings now include a direct Review setup action that opens Reliable Alarm setup.

The important Android issue fixed:

- Full-screen alarm was not appearing because Android treated the reliable alarm notification as too quiet/silent.
- The notification/channel behavior was corrected so Android allows the full-screen alarm UI.
- A later regression scheduled a test alarm for the next day due to ambiguous time selection. The editor now uses a clear AM/PM picker plus a Today/Tomorrow preview.
- The lock-screen alarm UI initially used raw pixel sizing, making buttons look like thin bars on Pixel density. It now uses density-independent sizing and custom styled native controls.
- Custom-minute repeat briefly behaved as “first fire after X minutes from now.” This was corrected: the first fire stays at the user-selected AM/PM time, then repeats every custom X minutes.
- DND readiness initially checked the wrong Android concept. Android has both broad Modes access and per-channel DND interruption/bypass state. The app now uses the `Reliable alarms` notification channel state for DND readiness.
- The app initially sent users to the broad Modes access page for DND repair. It now sends them to the `Reliable alarms` notification channel settings page, which is the relevant place to allow DND interruption.
- Pixel reports the lowest alarm slider position as a non-zero alarm stream volume. The app originally interpreted this as safe. It now requires alarm volume to be above Android's minimum level, because the minimum/bottom position is not reliable enough for spoken alarms.

Latest verified Pixel 8 behavior:

- Speaking Alarm fires correctly with the screen locked.
- Speaking Alarm repeats correctly using a custom 2-minute recurrence.
- Repeating alarm continues to work when the app is closed/removed from recent apps.
- Repeating alarm works while another foreground app, Instagram, is being used.
- When another app is foregrounded, the alarm appears as an alert/notification first, then takes over with the intended full-screen lock-screen flow when the phone is locked.
- Reboot recovery passed on Pixel 8.
- DND ON with `Reliable alarms` removed from interrupting apps still allowed Android alarm-clock style alarms to fire, which is acceptable Android behavior, but the app now detects and warns that the Reliable alarms channel is not DND-ready.
- Reliable Alarm status correctly shows Do Not Disturb as not ready when the `Reliable alarms` channel cannot interrupt DND.
- Low alarm-volume handling passed on Pixel 8: when a repeating Alarm Reminder was running, lowering alarm volume to the bottom level triggered an in-app warning; raising it cleared the warning, and the next repeat still fired correctly.
- Nearby alarm overlap passed on Pixel 8: a Speaking Alarm fired, was snoozed for 5 minutes, an Alarm Reminder fired one minute later and was acknowledged, then the snoozed Speaking Alarm returned correctly.
- Three nearby one-time alarms passed on Pixel 8: Speaking Alarm, Alarm Reminder, and Speaking Alarm fired in sequence and each acknowledged cleanly.
- Long-running repeat soak test was user-tested and passed.
- Notification-permission revoked flow was user-tested and passed.

## Recent progress log

This section captures the latest completed product and UX work after the Android reliability foundation became stable.

### Phase 3A — Add Reminder and mode selection polish

Completed:

- Rebuilt the Add Reminder flow as a calmer card-based sheet.
- Replaced the delivery-mode dropdown/chips with three clear behavior cards:
  - Gentle Reminder
  - Alarm Reminder
  - Speaking Alarm
- Made title, category, first reminder time, repeat, delivery mode, tone, and spoken message feel more guided.
- Added a clearer custom-minute explanation: first fire stays at the selected time, then repeats every X minutes.
- Made the spoken-message field appear only for Speaking Alarm.
- Changed tone selection into built-in tone chips.
- Added save validation so a reminder needs a title before saving.

### Phase 3B — Gentle Reminder behavior

Completed:

- Added Done and Remind again actions to Gentle Reminder notifications.
- Made Remind again act as a lightweight gentle snooze rather than a full-screen alarm snooze.
- Added per-reminder “Remind again after” options:
  - 2 min
  - 5 min
  - 10 min
  - 15 min
  - 30 min
- Updated the Gentle notification action label to show the chosen duration, such as `Remind in 2 min`.
- Added `2 min` as a snooze option for Alarm Reminder and Speaking Alarm too.

### Alarm Reminder / Speaking Alarm notification actions

Completed:

- Added Snooze to the heads-up notification shown while another app is in use.
- The heads-up notification now supports:
  - Acknowledge
  - Snooze X min
- Snooze from notification stops current playback and reschedules the same alarm with its title, tone, spoken message, and repeat rule.
- User-tested on Pixel 8 and confirmed working.

### Phase 3C — Today screen polish

Completed:

- Reworked the Today header into a calm card with dynamic greeting.
- Moved reliability warnings higher on the Today screen.
- Added a direct Review setup action for reliability warnings.
- Reworked the Next Up card with:
  - delivery-mode badge
  - repeat badge
  - tone badge
  - Speaking badge when relevant
  - paused state
  - Open reminder action
- Removed the fake Today-screen snooze snackbar action.
- Improved Later Today rows with clearer title/time hierarchy, delivery badges, repeat badges, and disabled styling.
- Improved empty state with friendlier copy and quick examples.

### Phase 3D — Routines/templates polish

Completed:

- Reworked Routines into a polished template-driven page.
- Added six quick-start templates:
  - Drink water
  - Stand and stretch
  - Eye break
  - Medication
  - Meeting prep
  - Deep work break
- Templates now pre-fill Add Reminder with:
  - title
  - category
  - reminder mode
  - repeat rule
  - tone
  - spoken message where relevant
  - snooze/remind-again duration
- Added a cleaner Your routines section with empty state and count badge.

### Phase 3E — Settings and onboarding polish

Completed:

- Reworked Settings into a control-center style page.
- Added a polished Settings header card.
- Added a Reliable Alarm readiness card showing Checking, Ready, or Needs attention.
- Added Review setup action inside Settings.
- Added sections for:
  - Reliability
  - Reminder behavior
  - Integrations
  - Preferences
- Added Google Calendar and Microsoft Teams / Outlook placeholders for Phase 4.
- Added a Troubleshooting/debug placeholder.
- Cleaned up non-clickable placeholder rows so they no longer show navigation chevrons.
- Polished onboarding copy to feel calmer and less technical.

### Phase 3F — Code structure refactor

Completed:

- Split the previous 3000+ line `lib/main.dart` into feature-focused files.
- Reduced `lib/main.dart` to the app entrypoint plus library part declarations.
- Added a clearer `lib/` structure:
  - `app/`
  - `models/`
  - `screens/onboarding/`
  - `screens/today/`
  - `screens/routines/`
  - `screens/settings/`
  - `screens/reminder_detail/`
  - `screens/reminder_editor/`
  - `widgets/` planned for later standalone shared widgets
  - `utils/`
- Kept behavior and UI unchanged during the split.
- Used Dart part files for the first safe extraction pass so private helpers could keep working while the project was reorganized.
- Verified the refactor with:
  - `dart format lib`
  - `flutter analyze`
  - `flutter test`
  - Android debug APK build
  - Pixel 8 install and launch

Next cleanup step:

- Gradually convert some part files into normal imported Dart libraries where it improves maintainability.
- Move shared widgets such as badges and reminder icons into `widgets/`.
- Move pure formatting/time helpers into independent utility imports.

### Phase 3G — Visual identity pass

Planned and now in progress:

- Adopt the Linen / Dark Wine / Ash Grey direction as the main product palette.
- Use Scarlet Glacier only as inspiration for soft gradients, not as the dominant palette.
- Add shared design tokens for:
  - Linen background
  - Dark Wine primary accent
  - Ash Grey calm/support color
  - Soft Snow card surfaces
  - Blush/Wine gradient accents
- Redesign onboarding with:
  - gradient background
  - slim top progress line
  - no global Skip button
  - calmer permission copy and stronger setup flow
- Add gradient treatment to important hero cards, especially Next Up.
- Move primary CTAs toward Dark Wine while keeping secondary chips calm with Ash Grey/Sage.
- Keep behavior unchanged during this pass; this is a visual-system update only.

Completed in first implementation pass:

- Added the new visual identity tokens:
  - Linen
  - Dark Wine
  - Muted Wine
  - Ash Grey
  - Bright Snow
  - Blush
  - Periwinkle Mist for later optional accents
- Added shared gradients:
  - onboarding gradient
  - hero gradient
  - wine hero gradient
  - soft card gradient
- Updated the Material theme to use Dark Wine as the primary color.
- Updated primary buttons and floating action button to use Dark Wine / Linen.
- Redesigned onboarding with:
  - full-screen gradient background
  - slim rounded top progress line
  - progress count pill
  - soft glass-like content card
  - no global Skip button
  - Back-only navigation for previous steps
- Applied first Today screen visual pass:
  - gradient header card
  - gradient Next Up hero card
  - important Alarm/Speaking reminders use wine-gradient hero treatment
  - Gentle reminders use the softer linen/ash gradient treatment
  - softer warning card, empty card, reminder rows, and reliability note
- Verified with:
  - `dart format lib`
  - `flutter analyze`
  - `flutter test`
  - Android debug APK build
  - Pixel 8 install and launch

Completed in second implementation pass:

- Applied the Linen / Dark Wine / Ash Grey visual identity to the Add Reminder editor.
- Updated Add Reminder cards with soft gradients, wine-accent icons, calmer selected states, and clearer mode-card hierarchy.
- Updated delivery-mode accent colors:
  - Gentle stays calm and muted.
  - Alarm Reminder uses Dark Wine.
  - Speaking Alarm uses Muted Wine.
- Applied the visual identity to Routines:
  - gradient header card
  - softer routine template cards
  - Dark Wine navigation/accent treatment
- Applied the visual identity to Settings:
  - gradient header card
  - upgraded Reliable Alarm readiness card
  - softer setting tiles
  - Dark Wine icons and repair actions
- Applied the visual identity to Reliable Alarm setup:
  - gradient status card
  - softer readiness rows
  - clearer Dark Wine / Muted Wine status treatment
- Applied the visual identity to Reminder Details:
  - softened detail cards
  - refreshed enabled toggle card
  - calmer visual framing around the reminder icon
- Verified with:
  - `dart format lib`
  - `flutter analyze`
  - `flutter test`
  - Android debug APK build
  - Pixel 8 install and launch

Completed in third implementation pass:

- Reduced the “too many cards / CRM dashboard” feeling on the core screens.
- Redesigned onboarding so each step no longer sits inside a large filled white card.
- Kept onboarding as a full-screen gradient experience with:
  - slim progress line
  - direct content on the gradient
  - larger soft icon surface
  - small status pill only when a permission/check has a readiness state
  - primary action near the main content
- Simplified the Today header by removing the card wrapper around the greeting/date.
- Redesigned the Next Up hero as the main emotional/visual object on the Today page.
- Added the full reminder delivery type inside the Next Up hero, such as:
  - Gentle Reminder
  - Alarm Reminder
  - Speaking Alarm
- Gave Gentle/Water-style next reminders a softer water-like gradient treatment.
- Reduced badge clutter in the Next Up hero by replacing multiple pills with one clear metadata line.
- Simplified Later Today rows so they feel more like a schedule list and less like stacked CRM cards.
- Fixed Reminder Details so the Snooze / Remind again button uses the reminder’s actual selected duration instead of hardcoded `10 min`.
- Verified with:
  - `dart format lib`
  - `flutter analyze`
  - `flutter test`
  - Android debug APK build
  - Pixel 8 install and launch

Completed in fourth implementation pass:

- Started adapting the app toward the new ChatGPT Web reference UI direction while preserving current working behavior.
- Added a shared signature hero gradient inspired by the reference:
  - Dark Wine
  - Muted Wine
  - Blush/Hazel
  - Ash Grey
- Made the Today `Next up` hero use the same filled signature gradient consistently for all reminder types.
- Made the empty/quiet Today hero use the same signature gradient so the main card remains visually consistent before and after reminders exist.
- Added lightweight custom-painted reminder icons for:
  - water / droplet
  - alarm / bell
  - speaking / speaker
  - stretch
  - medication / pill
  - meeting / calendar
  - focus / target
  - reliability / shield
- Replaced Today reminder category icons with the custom icon system.
- Updated the Add/Edit Reminder bottom sheet to float from the bottom with a visible top gap instead of touching the top of the screen.
- Kept alarm scheduling, notification actions, native Android playback, and database behavior unchanged.
- Verified with:
  - `dart format lib`
  - `flutter analyze`
  - `flutter test`
  - Android debug APK build
  - Pixel 8 install and launch

Completed in fifth implementation pass:

- Migrated onboarding closer to the ChatGPT Web reference UI.
- Reworked onboarding from a longer technical permission sequence into a calmer 4-step flow:
  - Welcome
  - Reminder intensities
  - Reliable reminders
  - Ready
- Added reference-style onboarding dots.
- Added reminder intensity cards for:
  - Gentle reminder
  - Alarm reminder
  - Speaking reminder
- Added a Reliable reminders checklist screen with readiness states for:
  - Notifications
  - Exact alarms
  - Full-screen alarms
  - Do Not Disturb access
  - Alarm volume
- Kept existing Android permission actions and readiness checks intact.
- Migrated Add/Edit Reminder closer to the reference sheet style:
  - Cancel / Save top row
  - compact sheet title
  - direct title field
  - compact horizontal category tiles with custom icons
  - existing schedule/repeat/delivery/tone/snooze logic preserved
- Updated widget tests to match the new Add Reminder sheet title/action.
- Verified with:
  - `dart format lib`
  - `flutter analyze`
  - `flutter test`
  - Android debug APK build
  - Pixel 8 install and launch

Completed in sixth implementation pass:

- Removed onboarding escape paths:
  - no `Skip` button
  - no `I’ll set it up later`
  - no `Learn more` bypass on the Reliable reminders step
- Updated onboarding Reminder intensities so the three modes no longer sit inside heavy white cards.
- Updated Reminder intensities icons to use circular signature-gradient icon bubbles, matching the first onboarding screen’s visual language.
- Updated Reliable reminders checklist so each row keeps its own icon instead of replacing ready items with a generic checkmark.
- Made onboarding’s primary Reliable reminders action include the DND setup step instead of hiding DND behind only a row tap.
- Hardened Android DND settings opening with a fallback chain:
  - Reliable alarms notification channel settings
  - app notification settings
  - notification policy access settings
- Redesigned Reminder Detail toward the reference UI:
  - centered icon/title/time
  - compact Enabled switch
  - one grouped detail list
  - Edit/Duplicate/Delete action list
  - selected snooze/remind-again duration retained
- Redesigned Routines toward the reference UI:
  - title/subtitle header
  - 2-column template grid
  - wide Meeting Prep card
  - custom icons for templates
- Updated widget tests for the new routines grid.
- Verified with:
  - `dart format lib test`
  - `flutter analyze`
  - `flutter test`
  - Android debug APK build
  - Pixel 8 install and launch

Completed in seventh implementation pass:

- Separated onboarding Reliable reminders setup into individual row actions instead of one grouped enable flow.
- Each onboarding readiness item now has its own action:
  - Notifications: Allow
  - Exact alarms: Allow
  - Full-screen alarms: Open
  - Do Not Disturb: Open
  - Alarm volume: Check
- The Reliable reminders Continue button now stays unavailable until required setup is complete.
- Made all Reminder intensities icon artwork solid white inside the circular signature-gradient bubbles.
- Updated Routines template cards to use the same filled signature gradient as the Today `Next up` hero card.
- Lightly polished Settings and Reliable Alarm setup toward the reference direction:
  - simpler Settings header
  - clearer reliability setup entry
  - Reliable setup status icon bubble
  - readiness rows with specific icons
- Verified with:
  - `dart format lib test`
  - `flutter analyze`
  - `flutter test`
  - Android debug APK build
  - Pixel 8 install and launch

Completed in eighth implementation pass:

- Made the Today `Next up` hero card tappable across the full card surface.
- Kept the visible `Open reminder` affordance, but users no longer need to tap only that text.
- Made Add/Edit Reminder bottom sheets explicitly swipe-dismissable with drag enabled.
- Lightened Add/Edit Reminder row styling so section cards feel less heavy and closer to the reference sheet.
- Improved Routines gradient-card subtitle readability:
  - brighter subtitle text
  - stronger font weight
  - subtle shadow on gradient
- Polished native Android full-screen alarm UI visually only:
  - warmer gradient background
  - signature wine/blush/ash icon bubble
  - white alarm icon
  - softer mode pill
  - refined button radius/colors
- Preserved native alarm behavior:
  - acknowledge unchanged
  - snooze unchanged
  - scheduling unchanged
  - playback unchanged
- Verified with:
  - `dart format lib test`
  - `flutter analyze`
  - `flutter test`
  - Android debug APK build
  - Pixel 8 install and launch

Completed in ninth implementation pass:

- Fixed the final onboarding Ready screen so it matches the earlier onboarding visual language:
  - removed the white note box
  - changed the icon bubble to the signature gradient
  - made the ready icon white
  - kept the note as simple text on the gradient background
- Fixed the Today `Next up` hero square-edge artifact by removing the rectangular Ink fill under the rounded gradient card and clipping ripple behavior.
- Cleaned up Reminder Detail actions:
  - removed the top-right three-dot menu
  - removed duplicate/placeholder action from the action card
  - kept direct Edit reminder and Delete reminder actions in the main action card
- Verified with:
  - `dart format lib test`
  - `flutter analyze`
  - `flutter test`
  - Android debug APK build
  - Pixel 8 install and launch

Still to do in Phase 3G:

- Continue deeper Settings and Reliable Alarm setup reference polish after Pixel visual review.
- Continue refining Add/Edit Reminder row styling toward the reference UI while preserving behavior.
- Apply the new visual identity to the native full-screen alarm screen.
- Review contrast and readability on the Pixel after real-device visual inspection.
- Decide whether any screens need reduced gradients after real-device visual inspection.

### Verification after recent work

Completed after each meaningful change:

- `flutter analyze`
- `flutter test`
- Android debug APK build
- Pixel 8 install and launch when the device was connected

## Phase 1 — Android Reliable Alarm Foundation

Status: complete for Android foundation; reliability hardening has begun and several items are already verified on Pixel 8.

Included:

- Flutter app foundation
- Local reminder data
- Add/edit/delete reminders
- Gentle Reminder
- Alarm Reminder
- Speaking Alarm
- Native Android alarm scheduling
- Exact alarm support
- Full-screen alarm UI
- Snooze
- Acknowledge
- Permission readiness screen
- Pixel 8 real-device verification
- First-run onboarding
- 12-hour AM/PM time selection
- Today/Tomorrow schedule preview
- Custom-minute repeat rules
- Native Android recurrence handling
- Native scheduled-alarm persistence
- Boot/package-replaced recovery receiver
- Lock-screen alarm UI styling pass
- DND readiness detection based on the `Reliable alarms` notification channel
- DND repair routing to the `Reliable alarms` notification channel settings page
- Alarm volume readiness that treats the bottom/minimum alarm level as unsafe
- Direct repair path from Today screen warnings into Reliable Alarm setup

Remaining Phase 1 polish:

- Continue refining onboarding copy and visual polish.
- Improve next alarm time display after snooze/edit in the Today/detail screens.
- Add better empty states and disabled states.
- Continue refining permission warnings across onboarding, Today, and Settings.
- Add app update/reinstall behavior notes in Settings or a help/debug screen.
- Clean code structure before Phase 2.

## Before Phase 2 — First-run onboarding and Phase 1 polish

Before starting Phase 2, the app should guide the user through a proper first-time setup flow.

Goal:

- When the app is opened for the first time, take the user through an interactive onboarding process.
- Ask for permissions one by one inside the onboarding flow.
- Avoid making the user discover the Reliable Alarm setup screen manually.
- Make the user understand why each permission matters.
- Keep the flow simple and calm, not technical.

Proposed onboarding screens:

1. Welcome
   - Explain the app in one simple line: Speaking Clock helps you remember important things when work pulls you too deep.

2. Choose reminder style
   - Explain the three types:
     - Gentle Reminder: a light notification/reminder.
     - Alarm Reminder: a full-screen alarm until acknowledged.
     - Speaking Alarm: speaks the custom message, then continues ringing until acknowledged.

3. Notifications permission
   - Ask for notification permission.
   - Explain that reminders cannot appear without it.

4. Exact alarms permission
   - Ask the user to allow exact alarms.
   - Explain that important alarms need to fire at the correct time.

5. Full-screen alarm permission
   - Ask the user to allow full-screen alarm behavior.
   - Explain that this is needed for lock-screen alarm screens.

6. Do Not Disturb guidance
   - Guide the user to allow alarm behavior during Do Not Disturb.
   - Explain clearly that this is optional but recommended for reliable alarms.

7. Alarm volume check
   - Check whether alarm volume is above Android's lowest/minimum level.
   - Guide the user if volume is muted or too low to trust.

8. Test alarm
   - Let the user trigger a short test alarm to confirm setup.

9. Setup complete
   - Show confirmation and take the user to Today screen.

Important behavior:

- Onboarding should appear only on first app launch.
- If the user skips a permission, the app should still work, but it should clearly show which features may be inconsistent.
- The app should continue to re-check permission health later because Android settings can change after app updates, reinstalls, or user changes.

Implementation status:

- First-run onboarding has been implemented.
- Permission screens/actions are connected to Android settings where Android requires settings pages.
- The latest test intentionally allowed the user to grant permissions through the app flow instead of granting them through USB/ADB.
- DND repair now routes to the specific Reliable alarms notification channel settings page, because broad Modes access can be ON while the Reliable alarms channel still cannot interrupt DND.
- Alarm volume copy and readiness now use "above the lowest level" instead of "above zero" because Pixel can report the bottom alarm level as non-zero.
- Further polish is still needed so onboarding feels more premium and less like a setup checklist.

## Phase 2 — Android Stability and Real-World Reliability

Status: main Android reliability pass complete on Pixel 8; remaining items are deeper edge-case hardening and debug tooling.

Main goal:

- Make Android reliable under real phone conditions.

Build next:

- Continue rechecking permissions whenever the app opens.
- If a permission gets turned off, show a clear warning.
- Continue improving Do Not Disturb guidance text.
- Better handling if exact alarm permission is revoked.
- Better handling if notification permission is revoked.
- Better handling if full-screen alarm permission is revoked.
- Better handling if alarm volume is lowered to Android's minimum/bottom level while repeats are active.
- Make alarm state persistent:
  - scheduled
  - fired
  - snoozed
  - acknowledged
- Add a logs/debug screen for testing.

Verified test coverage:

- Locked phone — verified on Pixel 8.
- Screen off — partially covered by locked-screen testing.
- Do Not Disturb on/off — partially verified on Pixel 8.
- Silent mode and alarm-volume variations — verified on Pixel 8.
- App closed/removed from recent apps — verified on Pixel 8.
- Another app in foreground — verified with Instagram on Pixel 8.
- After reboot — verified on Pixel 8.
- After snooze — verified on Pixel 8.
- Custom-minute recurrence — verified with 2-minute repeat on Pixel 8.
- Multiple nearby alarms — overlap/snooze case and three-alarm sequence verified on Pixel 8.
- Long-running repeat soak — user-tested and passed.
- Notification permission revoked after setup — user-tested and passed.

Already implemented or partially implemented:

- Native Android scheduled-alarm persistence.
- Boot/package-replaced receiver.
- Native custom-minute recurrence.
- Schedule logging for easier diagnosis.
- Permission readiness checks on app resume.
- Reboot recovery verified on physical Pixel 8.
- DND readiness based on Reliable alarms channel bypass/interruption state.
- DND setup opens Reliable alarms channel settings instead of broad Modes access.
- Alarm volume readiness blocks scheduling when alarm volume is muted or at the bottom/minimum level.
- Today screen permission warnings can now open Reliable Alarm setup directly.

Remaining reliability backlog:

- DND repair flow after opening the Reliable alarms channel settings page.
- Exact alarm permission revoked after setup.
- Full-screen alarm permission revoked after setup.
- Multiple simultaneous alarms at the exact same minute.
- Longer multi-hour repeat soak.
- Add an in-app debug/status screen for scheduled alarms and permission state.
- Code structure cleanup before calendar integrations and iOS work.

## Phase 3 — UX Polish

Current active phase.

Main goal:

- Make the app feel calm, premium, and easy to use rather than like a technical prototype.

Phase 3 product goals:

- Make reminder creation feel effortless.
- Make the three reminder types obvious and emotionally distinct.
- Make Gentle Reminder useful instead of feeling like a weak notification.
- Make the app feel visually consistent across Today, Routines, Settings, onboarding, editor, and alarm screens.
- Reduce technical wording without hiding important reliability warnings.

Build sequence:

1. Reminder creation flow polish
   - Improve Add Reminder screen layout.
   - Make title, time, repeat, mode, tone, and spoken message feel guided.
   - Make AM/PM and Today/Tomorrow preview clearer.
   - Make custom-minute repeat easier to understand.
   - Add better validation messages before saving.
   - Status: implemented in Phase 3A as a card-based Add Reminder flow.

2. Reminder mode redesign
   - Gentle Reminder: light but useful.
   - Alarm Reminder: full-screen ringing until acknowledged.
   - Speaking Alarm: spoken text first, then ringing until acknowledged.
   - Add clearer descriptions and visual treatment for each mode.
   - Status: implemented in Phase 3A with three selectable behavior cards.

3. Gentle Reminder improvement
   - Improve notification behavior.
   - Add useful actions such as Done and Remind again.
   - Make it feel different from Alarm Reminder without being too weak.
   - Decide whether Gentle Reminder should support optional light snooze.
   - Status: first pass implemented with Done and Remind again notification actions.

4. Tone picker polish
   - Improve tone selection UI.
   - Show tone names more clearly.
   - Add preview/test behavior later if needed.
   - Keep built-in tones for now.
   - Status: first pass implemented with built-in tone chips.

5. Spoken message field polish
   - Make the custom spoken text field more prominent for Speaking Alarm.
   - Add examples such as “Drink water now” or “Meeting starts in 10 minutes.”
   - Make default spoken text clearer when the field is empty.
   - Status: first pass implemented; field now appears only for Speaking Alarm.

6. Today screen polish
   - Improve next-up card.
   - Improve “Later today” grouping.
   - Improve empty states.
   - Show clearer status for disabled reminders.
   - Improve next alarm time display after snooze/edit.
   - Status: first pass implemented with polished header, readiness warning placement, richer Next Up card, improved reminder rows, and calmer empty state.

7. Routines polish
   - Make quick-start routines actually useful.
   - Add templates like Drink water, Stretch, Eye break, Medication, Meeting prep.
   - Let templates pre-fill title, type, repeat, tone, and delivery mode.
   - Status: first pass implemented with six richer routine templates and pre-filled Add Reminder drafts.

8. Settings and onboarding polish
   - Make onboarding feel premium and less checklist-like.
   - Improve Reliable Alarm wording.
   - Add a simple help/debug section later for Android reliability state.
   - Status: first pass implemented with Settings control-center layout, readiness card, integration placeholders, and calmer onboarding copy.

9. Native full-screen alarm polish
   - Keep current working behavior stable.
   - Refine spacing, typography, icon, and button states only where safe.
   - Avoid risky changes to playback/scheduling during UX polish.
   - Status: first visual polish pass implemented with warmer gradient surface, cleaner alarm icon treatment, and calmer acknowledge/snooze buttons.

10. Reminder Detail and gradient readability polish
   - Replace the old Reminder Detail overflow/menu/list-action pattern with visible, intentional management buttons.
   - Edit is now the primary filled action; Delete is a direct but quieter outlined destructive action that still confirms before removing the reminder.
   - Keep snooze/remind-again as a separate runtime action so it does not visually compete with edit/delete management.
   - Add a shared soft text-shadow helper for white text on gradient surfaces.
   - Apply the shadow consistently to Today hero text, empty-state gradient copy, and Routine template card text for better readability.
   - Status: implemented; needs Pixel visual QA on Reminder Detail, Today hero, empty Today state, and Routines templates.

11. Add/Edit, Settings, and Reminder Detail hierarchy polish
   - Add/Edit Reminder now opens with a gradient creation hero containing the title field and category selector, making the sheet feel less like a raw form.
   - Category chips now have a dedicated gradient-surface style with stronger frosted contrast, dark wine icons/text, and clearer selected states so they stay readable across the whole gradient.
   - Editor section cards now use the shared `SoftPanel` surface for consistent borders, radius, and lift.
   - Repeat, tone, and snooze/remind-again controls now use custom Speaking Clock pill controls instead of default Flutter choice chips.
   - Delivery-mode cards now use a stronger selected-gradient treatment with white text, clearer badges, and softer unselected cards.
   - Reminder Detail now has a gradient hero for icon, title, time, delivery type, and enabled/paused state.
   - Settings reliability status now uses the signature gradient hero treatment, with readable white text and a clearer review button.
   - Settings rows and Reliable Alarm setup rows now use custom icon bubbles and softer `SoftPanel` cards instead of default list-tile styling.
   - Status: implemented; needs Pixel visual QA on Add/Edit sheet category visibility, Repeat, Tone, Snooze, and Delivery-mode selection.

Next UI corrections to consider:

- Add/Edit Reminder may still need spacing refinements after real-device review, especially around the horizontal category scroller and long tone labels.
- Reminder Detail action hierarchy should be tested: Edit/Delete may stay as two buttons, or we may move Delete lower if it feels too visible.
- Onboarding permission pages are functionally separated now, but each permission step can still be made more guided with clearer Android setting return states.
- Gentle Reminder notification/detail language should remain distinct from Alarm Reminder and Speaking Alarm so users understand it is intentionally lighter.

Acceptance criteria:

- A first-time user can create a useful reminder without needing explanation.
- The difference between Gentle Reminder, Alarm Reminder, and Speaking Alarm is obvious.
- Gentle Reminder feels intentionally lightweight, not broken or too quiet.
- Existing Android reliability tests still pass after UI changes.
- The visual design remains minimal, calm, cream/sage, and easy on the eyes.

Original Phase 3 ideas:

- Better reminder creation flow.
- Better tone picker.
- Better spoken message field.
- Better routine templates.
- Better Today screen grouping.
- Gentle Reminder behavior improvement.
- Clear difference between Gentle, Alarm, and Speaking Alarm.
- More polished full-screen alarm design.
- Better onboarding copy and visual polish.

## Phase 4 — Calendar Integrations

Main goal:

- Add Google Calendar and Microsoft calendar reminders.

Build:

- Connect Google Calendar.
- Pull meeting events.
- Let the user choose spoken meeting reminders 10 minutes before the meeting.
- Later add Microsoft Teams/Outlook Calendar support.
- Add meeting-specific reminder templates.

Note:

- This should not start before Android alarm reliability is fully stable.

## Phase 5 — iOS Version

Main goal:

- Bring the same product philosophy to iPhone while respecting iOS limitations.

Important:

- iOS cannot be made as flexible as Android for full-screen alarm-style behavior unless using allowed system paths.
- The iOS version should be designed carefully instead of pretending it can bypass everything like Android.

Build:

- Flutter iOS UI.
- iOS notification/reminder support.
- iOS permission onboarding.
- iPhone simulator testing.
- Later real iPhone testing if available.

## Recommended immediate next step

Move into Phase 3 UX polish while keeping Phase 2 reliability as a regression suite:

1. Polish the Add Reminder flow.
2. Improve reminder-mode selection and explanations.
3. Upgrade Gentle Reminder behavior.
4. Improve tone picker and spoken message field.
5. Re-run Android reliability tests after each meaningful UX change.
6. Keep debug/status tooling as a Phase 2 backlog item unless reliability issues reappear.
