# Speaking Clock — Current Standing and Roadmap

## Current standing

Android Phase 1 core alarm engine is working on the physical Pixel 8, and the first Android reliability pass is now verified under real-world conditions.

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

The important Android issue fixed:

- Full-screen alarm was not appearing because Android treated the reliable alarm notification as too quiet/silent.
- The notification/channel behavior was corrected so Android allows the full-screen alarm UI.
- A later regression scheduled a test alarm for the next day due to ambiguous time selection. The editor now uses a clear AM/PM picker plus a Today/Tomorrow preview.
- The lock-screen alarm UI initially used raw pixel sizing, making buttons look like thin bars on Pixel density. It now uses density-independent sizing and custom styled native controls.
- Custom-minute repeat briefly behaved as “first fire after X minutes from now.” This was corrected: the first fire stays at the user-selected AM/PM time, then repeats every custom X minutes.
- DND readiness initially checked the wrong Android concept. Android has both broad Modes access and per-channel DND interruption/bypass state. The app now uses the `Reliable alarms` notification channel state for DND readiness.
- The app initially sent users to the broad Modes access page for DND repair. It now sends them to the `Reliable alarms` notification channel settings page, which is the relevant place to allow DND interruption.

Latest verified Pixel 8 behavior:

- Speaking Alarm fires correctly with the screen locked.
- Speaking Alarm repeats correctly using a custom 2-minute recurrence.
- Repeating alarm continues to work when the app is closed/removed from recent apps.
- Repeating alarm works while another foreground app, Instagram, is being used.
- When another app is foregrounded, the alarm appears as an alert/notification first, then takes over with the intended full-screen lock-screen flow when the phone is locked.
- Reboot recovery passed on Pixel 8.
- DND ON with `Reliable alarms` removed from interrupting apps still allowed Android alarm-clock style alarms to fire, which is acceptable Android behavior, but the app now detects and warns that the Reliable alarms channel is not DND-ready.
- Reliable Alarm status correctly shows Do Not Disturb as not ready when the `Reliable alarms` channel cannot interrupt DND.

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
   - Check whether alarm volume is above zero.
   - Guide the user if volume is muted.

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
- Further polish is still needed so onboarding feels more premium and less like a setup checklist.

## Phase 2 — Android Stability and Real-World Reliability

Current active phase.

Main goal:

- Make Android reliable under real phone conditions.

Build next:

- Continue rechecking permissions whenever the app opens.
- If a permission gets turned off, show a clear warning.
- Continue improving Do Not Disturb guidance text.
- Better handling if exact alarm permission is revoked.
- Better handling if notification permission is revoked.
- Better handling if full-screen alarm permission is revoked.
- Make alarm state persistent:
  - scheduled
  - fired
  - snoozed
  - acknowledged
- Add a logs/debug screen for testing.

Test:

- Locked phone — verified on Pixel 8.
- Screen off — partially covered by locked-screen testing.
- Do Not Disturb on/off — partially verified on Pixel 8.
- Silent mode
- App closed/removed from recent apps — verified on Pixel 8.
- Another app in foreground — verified with Instagram on Pixel 8.
- After reboot — verified on Pixel 8.
- After snooze
- Custom-minute recurrence — verified with 2-minute repeat on Pixel 8.
- Multiple alarms

Already implemented or partially implemented:

- Native Android scheduled-alarm persistence.
- Boot/package-replaced receiver.
- Native custom-minute recurrence.
- Schedule logging for easier diagnosis.
- Permission readiness checks on app resume.
- Reboot recovery verified on physical Pixel 8.
- DND readiness based on Reliable alarms channel bypass/interruption state.
- DND setup opens Reliable alarms channel settings instead of broad Modes access.

Still needs explicit verification:

- DND repair flow after opening the Reliable alarms channel settings page.
- Silent mode behavior with alarm volume and media volume variations.
- Permission revoked after setup.
- Multiple simultaneous/nearby alarms.
- Long-running repeat behavior over several hours.

## Phase 3 — UX Polish

Main goal:

- Make the app feel calm, premium, and easy to use rather than like a technical prototype.

Build:

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

Continue Phase 2 by verifying and hardening Android reliability:

1. Verify the DND repair flow now opens the Reliable alarms channel settings and lets the user restore DND interruption.
2. Test silent mode and alarm-volume behavior.
3. Add an in-app debug/status screen for scheduled alarms and permission state.
4. Improve permission warnings when notification, exact alarm, full-screen, DND, or alarm volume becomes unsafe.
5. Test multiple nearby alarms and long-running repeat behavior.
6. Clean up code structure before adding calendar integrations or iOS work.
