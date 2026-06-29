# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project layout

The Flutter app lives in `alarmlock/`. All development commands run from that directory. The git repo root is `PushAlarm/` and only contains `alarmlock/` plus `.gitignore`.

## Common commands

All commands must be run from `alarmlock/`:

```bash
flutter pub get          # install / sync dependencies
flutter analyze          # lint (zero issues expected before committing)
flutter run              # run on connected Android device
flutter run --release    # release build (uses debug signing key)
flutter build apk        # build APK
```

There is no test suite beyond the placeholder in `test/widget_test.dart`. Run `flutter test` to execute it.

Must run on a **real Android device** — ML Kit pose detection requires a physical camera and `android_alarm_manager_plus` requires the Android alarm subsystem.

## Architecture

### Alarm firing flow (the most important thing to understand)

There are two separate Dart environments involved:

1. **Background isolate** (`AlarmService.alarmCallback`) — fired by `android_alarm_manager_plus` at the scheduled time, even when the app is closed. It writes the alarm ID to `SharedPreferences` and shows a full-screen notification via `NotificationService`. This function is top-level and annotated `@pragma('vm:entry-point')`.

2. **Main isolate** (the Flutter app) — on startup, `main()` checks `SharedPreferences` for a pending alarm ID and launches `WorkoutScreen` directly if one is found. If the app is already running when the notification is tapped, `NotificationService._onResponse` uses `navigatorKey` (defined in `app_keys.dart`) to push `/workout`.

This means any change to the alarm-firing path must consider both paths.

### State management

Provider pattern with two `ChangeNotifier`s, both registered in `main.dart`:

- **`AlarmsProvider`** — source of truth for the alarm list. Every mutation (add/update/delete/toggle) goes through it; it handles both DB writes and `AlarmService` schedule/cancel in the same call.
- **`StatsProvider`** — reads all `workout_logs` from the DB and computes totals, streaks, and the 7-day bar chart data. Call `load()` after inserting a new log (done in `WorkoutScreen._onComplete`).

### Push-up detection

`WorkoutScreen` runs a camera image stream → ML Kit `PoseDetector` (stream mode) → `_computeRepState()`.

**Critical:** `_computeRepState` is a pure function that returns `(newRepCount, newPhase, targetReached)`. It must never call `setState` internally. The caller sets state first, then calls `_onComplete()` afterwards — this prevents the nested-setState crash.

Rep counting logic (in `pose_painter.dart`'s `elbowAngle` + `_computeRepState`):
- Average elbow angle (left + right) below 90° → DOWN phase
- Average elbow angle above 160° while in DOWN → UP phase, increment counter
- Minimum landmark likelihood threshold: 0.5

`PosePainter` (`pose_painter.dart`) handles coordinate translation from image space to canvas space, including the 90°/270° sensor rotation swap and front-camera horizontal flip.

### Database schema (`pushalarm.db`, SQLite via sqflite)

```
alarms: id, hour, minute, label, days (7-char string "1010111"), push_up_count, is_enabled
workout_logs: id, alarm_id, date (ms since epoch), push_ups_completed, target_push_ups
```

`DatabaseHelper` is a singleton. Schema migrations require bumping the version int in `_initDb` and adding an `onUpgrade` handler.

`Alarm.days` is `List<bool>` in Dart (index 0 = Monday, 6 = Sunday, matching `DateTime.weekday - 1`). Serialized as a 7-char string of `'1'`/`'0'` in the DB.

### Android specifics

- **min SDK 21**, package `com.example.alarmlock`
- Permissions declared in `android/app/src/main/AndroidManifest.xml`: `CAMERA`, `SCHEDULE_EXACT_ALARM`, `USE_EXACT_ALARM`, `WAKE_LOCK`, `FOREGROUND_SERVICE`, `USE_FULL_SCREEN_INTENT`, `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`
- The `AlarmBroadcastReceiver`, `RebootBroadcastReceiver`, and `AlarmService` entries in the manifest are required by `android_alarm_manager_plus` — do not remove them
- `MainActivity` has `android:showWhenLocked="true"` and `android:turnScreenOn="true"` so the alarm appears on the lock screen

### Alarm sound

`WorkoutScreen` plays `content://settings/system/alarm_alert` on loop via `audioplayers` when the screen opens. The play call is wrapped in a try/catch because some ROMs may not resolve the URI; in that case it fails silently (the notification sound already fired). Always call `_audioPlayer.stop()` before navigating away.
