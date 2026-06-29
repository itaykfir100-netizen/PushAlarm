import 'package:flutter/services.dart';
import '../app_keys.dart';
import '../models/alarm.dart';

const _channel = MethodChannel('com.example.alarmlock/alarm');

class AlarmService {
  static final AlarmService instance = AlarmService._();
  AlarmService._();

  // Call once in main() after WidgetsFlutterBinding.ensureInitialized().
  void setup() {
    _channel.setMethodCallHandler(_handleNativeCall);
  }

  // Kotlin calls this when the app is already running and a notification is tapped.
  Future<dynamic> _handleNativeCall(MethodCall call) async {
    if (call.method == 'alarmFired') {
      final alarmId = call.arguments as int;
      navigatorKey.currentState?.pushNamed('/workout', arguments: alarmId);
    }
  }

  Future<void> scheduleAlarm(Alarm alarm) async {
    if (alarm.id == null) return;
    final fireTime = alarm.nextFireTime();
    if (fireTime == null) return;
    await _channel.invokeMethod('scheduleAlarm', {
      'id': alarm.id!,
      'fireTimeMs': fireTime.millisecondsSinceEpoch,
    });
  }

  Future<void> cancelAlarm(int id) async {
    await _channel.invokeMethod('cancelAlarm', {'id': id});
  }

  // Reads from native AlarmPrefs written by AlarmForegroundService.
  // Non-null means an alarm is actively waiting to be completed.
  Future<int?> getActiveAlarmId() async {
    return await _channel.invokeMethod<int?>('getActiveAlarmId');
  }

  Future<bool> hasActiveAlarm() async => (await getActiveAlarmId()) != null;

  // Stops the foreground service (stops ringtone + dismisses notification).
  Future<void> clearActiveAlarm() async {
    await _channel.invokeMethod('stopAlarmService');
  }
}
