import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../app_keys.dart';

// Channel ID changed from pushalarm_channel so Android creates a fresh
// channel with audioAttributesUsage = alarm (bypasses DND, uses alarm volume).
const _channelId = 'pushalarm_alarm_v2';
const _channelName = 'Alarm';

class NotificationService {
  static final NotificationService instance = NotificationService._();
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  NotificationService._();

  Future<void> initialize() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      const InitializationSettings(android: android),
      onDidReceiveNotificationResponse: _onResponse,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundResponse,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
            audioAttributesUsage: AudioAttributesUsage.alarm,
          ),
        );
  }

  Future<void> showAlarmNotification(int alarmId) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      playSound: true,
      enableVibration: true,
      ongoing: true,
      autoCancel: false,
    );

    await _plugin.show(
      alarmId,
      'Time to wake up!',
      'Complete your push-ups to dismiss',
      const NotificationDetails(android: androidDetails),
      payload: alarmId.toString(),
    );
  }

  Future<void> cancelAlarmNotification(int alarmId) async {
    await _plugin.cancel(alarmId);
  }
}

void _onResponse(NotificationResponse response) {
  final alarmId = int.tryParse(response.payload ?? '');
  if (alarmId == null) return;
  navigatorKey.currentState?.pushNamedAndRemoveUntil(
    '/workout',
    (route) => route.isFirst,
    arguments: alarmId,
  );
}

@pragma('vm:entry-point')
void _onBackgroundResponse(NotificationResponse response) {}
