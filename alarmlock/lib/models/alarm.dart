import 'package:intl/intl.dart';

class Alarm {
  final int? id;
  final int hour;
  final int minute;
  final String label;
  final List<bool> days; // [Mon, Tue, Wed, Thu, Fri, Sat, Sun]
  final int pushUpCount;
  final bool isEnabled;

  const Alarm({
    this.id,
    required this.hour,
    required this.minute,
    this.label = '',
    required this.days,
    required this.pushUpCount,
    this.isEnabled = true,
  });

  String get timeString {
    final dt = DateTime(0, 1, 1, hour, minute);
    return DateFormat('h:mm a').format(dt);
  }

  // Next DateTime this alarm should fire, or null if disabled / no days set
  DateTime? nextFireTime() {
    if (!isEnabled) return null;
    final now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      final dayIndex = (now.weekday - 1 + i) % 7; // 0=Mon … 6=Sun
      if (!days[dayIndex]) continue;
      final candidate = DateTime(
        now.year, now.month, now.day + i,
        hour, minute,
      );
      if (candidate.isAfter(now)) return candidate;
    }
    return null;
  }

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'hour': hour,
        'minute': minute,
        'label': label,
        'days': days.map((d) => d ? '1' : '0').join(),
        'push_up_count': pushUpCount,
        'is_enabled': isEnabled ? 1 : 0,
      };

  factory Alarm.fromMap(Map<String, dynamic> map) {
    final daysStr = map['days'] as String;
    return Alarm(
      id: map['id'] as int?,
      hour: map['hour'] as int,
      minute: map['minute'] as int,
      label: map['label'] as String? ?? '',
      days: List.generate(7, (i) => i < daysStr.length && daysStr[i] == '1'),
      pushUpCount: map['push_up_count'] as int,
      isEnabled: (map['is_enabled'] as int) == 1,
    );
  }

  Alarm copyWith({
    int? id,
    int? hour,
    int? minute,
    String? label,
    List<bool>? days,
    int? pushUpCount,
    bool? isEnabled,
  }) =>
      Alarm(
        id: id ?? this.id,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
        label: label ?? this.label,
        days: days ?? List.from(this.days),
        pushUpCount: pushUpCount ?? this.pushUpCount,
        isEnabled: isEnabled ?? this.isEnabled,
      );
}
