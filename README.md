# PushAlarm 💪

An Android alarm app that **forces you to do push-ups** to turn it off.

## Features

- **Multiple alarms** — set different times and push-up targets for different days
- **Real-time pose detection** — ML Kit draws a skeleton on your body and counts every clean rep
- **No cheating** — only full-range push-ups count (down below 90°, up above 155°)
- **Stats dashboard** — track total push-ups, current streak, best streak, and weekly volume
- **Lock screen support** — alarm fires even on a locked phone

## Tech Stack

| Layer | Technology |
|---|---|
| Language | Kotlin |
| UI | Jetpack Compose + Material 3 |
| Pose Detection | Google ML Kit Pose Detection |
| Camera | CameraX |
| Database | Room |
| Architecture | MVVM + StateFlow |
| Alarms | AlarmManager (exact, wake-lock) |

## Screens

### Alarms List
- Dark theme matching iOS alarm aesthetics
- Toggle each alarm on/off
- See reps required at a glance
- "Simulate Alarm Firing" button for testing

### Set Alarm
- Material 3 time picker clock dial
- Day repeat selector (M T W Th F Sa Su)
- Push-up count with ± buttons and quick presets (5 / 10 / 15 / 20 / 30 / 50)
- Custom label

### Push-Up Detection
- Front camera activates automatically when alarm fires
- Green skeleton overlaid on your body in real time
- Large rep counter with circular progress ring
- Alarm sound + vibration stop the moment you hit your target

### Stats
- Total push-ups all-time
- Current and best streak (consecutive days completed)
- Average push-ups per session
- Weekly bar chart showing daily volume

## Building

1. Clone the repo
2. Open in Android Studio Ladybug or newer
3. Sync Gradle
4. Run on a device (API 26+) — pose detection requires a real camera

## Permissions Required

- `CAMERA` — for push-up detection
- `SCHEDULE_EXACT_ALARM` — to fire alarms at precise times
- `POST_NOTIFICATIONS` — for the alarm notification (Android 13+)
- `FOREGROUND_SERVICE` — to keep the alarm running
- `RECEIVE_BOOT_COMPLETED` — to reschedule alarms after reboot
