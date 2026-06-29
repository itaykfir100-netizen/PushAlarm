import 'package:flutter/foundation.dart';
import '../data/database_helper.dart';
import '../models/workout_log.dart';

class StatsProvider extends ChangeNotifier {
  List<WorkoutLog> _logs = [];

  int get totalPushUps => _logs.fold(0, (s, l) => s + l.pushUpsCompleted);
  int get totalSessions => _logs.length;
  double get avgPushUps => _logs.isEmpty ? 0 : totalPushUps / totalSessions;

  int get currentStreak {
    if (_logs.isEmpty) return 0;
    final days = _activeDaysSet();
    int streak = 0;
    var day = DateTime.now();
    while (true) {
      final key = _dayKey(day);
      if (!days.contains(key)) break;
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  int get bestStreak {
    if (_logs.isEmpty) return 0;
    final days = _activeDaysSet().toList()..sort();
    if (days.isEmpty) return 0;
    int best = 1, current = 1;
    for (int i = 1; i < days.length; i++) {
      final prev = DateTime.parse('${days[i - 1]}T00:00:00');
      final curr = DateTime.parse('${days[i]}T00:00:00');
      if (curr.difference(prev).inDays == 1) {
        current++;
        if (current > best) best = current;
      } else {
        current = 1;
      }
    }
    return best;
  }

  // Push-ups per day for the last 7 days (index 0 = 6 days ago, index 6 = today)
  List<double> get weeklyBars {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      final key = _dayKey(day);
      final dayLogs = _logs.where((l) => _dayKey(l.date) == key);
      return dayLogs.fold(0.0, (s, l) => s + l.pushUpsCompleted);
    });
  }

  Future<void> load() async {
    _logs = await DatabaseHelper.instance.getLogs();
    notifyListeners();
  }

  Set<String> _activeDaysSet() =>
      _logs.map((l) => _dayKey(l.date)).toSet();

  String _dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
