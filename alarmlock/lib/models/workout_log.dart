class WorkoutLog {
  final int? id;
  final int alarmId;
  final DateTime date;
  final int pushUpsCompleted;
  final int targetPushUps;

  const WorkoutLog({
    this.id,
    required this.alarmId,
    required this.date,
    required this.pushUpsCompleted,
    required this.targetPushUps,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'alarm_id': alarmId,
        'date': date.millisecondsSinceEpoch,
        'push_ups_completed': pushUpsCompleted,
        'target_push_ups': targetPushUps,
      };

  factory WorkoutLog.fromMap(Map<String, dynamic> map) => WorkoutLog(
        id: map['id'] as int?,
        alarmId: map['alarm_id'] as int,
        date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
        pushUpsCompleted: map['push_ups_completed'] as int,
        targetPushUps: map['target_push_ups'] as int,
      );
}
