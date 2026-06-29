import 'package:flutter/foundation.dart';
import '../data/database_helper.dart';
import '../models/alarm.dart';
import '../services/alarm_service.dart';

class AlarmsProvider extends ChangeNotifier {
  List<Alarm> _alarms = [];
  List<Alarm> get alarms => _alarms;

  Future<void> load() async {
    _alarms = await DatabaseHelper.instance.getAlarms();
    notifyListeners();
  }

  Future<void> addAlarm(Alarm alarm) async {
    final id = await DatabaseHelper.instance.insertAlarm(alarm);
    final saved = alarm.copyWith(id: id);
    if (saved.isEnabled) await AlarmService.instance.scheduleAlarm(saved);
    _alarms.add(saved);
    notifyListeners();
  }

  Future<void> updateAlarm(Alarm alarm) async {
    await AlarmService.instance.cancelAlarm(alarm.id!);
    await DatabaseHelper.instance.updateAlarm(alarm);
    if (alarm.isEnabled) await AlarmService.instance.scheduleAlarm(alarm);
    final idx = _alarms.indexWhere((a) => a.id == alarm.id);
    if (idx != -1) _alarms[idx] = alarm;
    notifyListeners();
  }

  Future<void> toggleAlarm(Alarm alarm) async {
    final updated = alarm.copyWith(isEnabled: !alarm.isEnabled);
    await updateAlarm(updated);
  }

  Future<void> deleteAlarm(int id) async {
    await AlarmService.instance.cancelAlarm(id);
    await DatabaseHelper.instance.deleteAlarm(id);
    _alarms.removeWhere((a) => a.id == id);
    notifyListeners();
  }
}
