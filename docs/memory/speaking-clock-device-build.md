---
name: speaking-clock-device-build
description: How to build/install Speaking Clock to the physical Pixel 8 (Flutter Android SDK wiring)
metadata: 
  node_type: memory
  type: project
  originSessionId: 168b7306-366a-4d0c-8677-81fb660ba7e7
  modified: 2026-07-28T14:16:17.116Z
---

Project: **Speaking Clock** (Flutter + native Android alarm engine) at `/Users/office/Documents/Speaking Clock 2`.

Deploying to the user's physical **Pixel 8** (`shiba`, id `39220DLJH000LW`):

- `ANDROID_HOME`/`ANDROID_SDK_ROOT` are **unset** in the shell, and `adb` is **not on PATH**. Flutter therefore does NOT see the Pixel by default.
- Fix (already applied once via `flutter config --android-sdk "$HOME/Library/Android/sdk"`, which persists): the SDK lives at `~/Library/Android/sdk`, adb at `~/Library/Android/sdk/platform-tools/adb`.
- For each build/install command, prefix with:
  `export ANDROID_HOME="$HOME/Library/Android/sdk" && export PATH="$ANDROID_HOME/platform-tools:$PATH"`
- Release is signed with the **debug** key (`android/app/build.gradle.kts`), so `flutter build apk --release` works with no keystore.
- Install + launch:
  `adb -s 39220DLJH000LW install -r build/app/outputs/flutter-apk/app-release.apk`
  `adb -s 39220DLJH000LW shell monkey -p com.example.speaking_clock -c android.intent.category.LAUNCHER 1`
- To review onboarding (first-run only): `adb -s 39220DLJH000LW shell pm clear com.example.speaking_clock` (wipes reminders; app re-seeds 3 defaults on next launch).
- Release builds take ~2–3 min. Run them in the background.
- Verification convention: `dart format lib test` → `flutter analyze` → `flutter test` → build → install. Never break the native alarm engine (see [[speaking-clock-lumen-redesign]]).
