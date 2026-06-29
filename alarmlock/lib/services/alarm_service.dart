import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alarm.dart';
import 'notification_service.dart';

const _activeAlarmKey = 'active_alarm_id';

// Runs in a background isolate inside android_alarm_manager_plus's foreground
// service. Plays looping alarm audio and keeps running until the user finishes
// their push-ups (which clears _activeAlarmKey from SharedPreferences).
@pragma('vm:entry-point')
Future<void> alarmCallback(int id) async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(_activeAlarmKey, id);

  await NotificationService.instance.initialize();
  await NotificationService.instance.showAlarmNotification(id);

  // Play looping alarm sound via RingtoneManager (bypasses DND, uses alarm
  // volume). The AlarmService foreground service keeps this isolate alive.
  final ringtone = FlutterRingtonePlayer();
  try {
    await ringtone.playAlarm(looping: true, asAlarm: true);
  } catch (_) {}

  // Block until the main isolate clears the alarm (push-ups completed).
  while (true) {
    await Future.delayed(const Duration(seconds: 1));
    await prefs.reload();
    if (prefs.getInt(_activeAlarmKey) != id) break;
  }

  try {
    await ringtone.stop();
  } catch (_) {}
}

class AlarmService {
  static final AlarmService instance = AlarmService._();
  AlarmService._();

  Future<void> init() => AndroidAlarmManager.initialize();

  Future<void> scheduleAlarm(Alarm alarm) async {
    assert(alarm.id != null);
    final fireTime = alarm.nextFireTime();
    if (fireTime == null) return;

    await AndroidAlarmManager.oneShotAt(
      fireTime,
      alarm.id!,
      alarmCallback,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
      alarmClock: true,
    );
  }

  Future<void> cancelAlarm(int id) async {
    await AndroidAlarmManager.cancel(id);
    await NotificationService.instance.cancelAlarmNotification(id);
    final prefs = await SharedPreferences.getInstance();
    if ((prefs.getInt(_activeAlarmKey) ?? -1) == id) {
      await prefs.remove(_activeAlarmKey);
    }
  }

  Future<int?> getActiveAlarmId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_activeAlarmKey);
  }

  // True when a real alarm fired and is waiting to be completed.
  // False in simulate mode (alarmCallback was never called).
  Future<bool> hasActiveAlarm() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_activeAlarmKey);
  }

  Future<void> clearActiveAlarm() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(_activeAlarmKey);
    if (id != null) {
      await NotificationService.instance.cancelAlarmNotification(id);
      await prefs.remove(_activeAlarmKey);
      // The background alarmCallback loop will detect the key is gone
      // and stop the audio on its own within ~1 second.
    }
  }
}
