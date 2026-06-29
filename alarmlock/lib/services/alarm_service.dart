import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alarm.dart';
import 'notification_service.dart';

const _activeAlarmKey = 'active_alarm_id';

// Top-level callback — runs in a background isolate when an alarm fires.
@pragma('vm:entry-point')
Future<void> alarmCallback(int id) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(_activeAlarmKey, id);
  await NotificationService.instance.initialize();
  await NotificationService.instance.showAlarmNotification(id);
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

  Future<void> clearActiveAlarm() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(_activeAlarmKey);
    if (id != null) {
      await NotificationService.instance.cancelAlarmNotification(id);
      await prefs.remove(_activeAlarmKey);
    }
  }
}
