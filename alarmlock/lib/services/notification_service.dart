import 'package:flutter_local_notifications/flutter_local_notifications.dart';

const _channelId = 'pushalarm_channel';
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
  // Handled in main.dart via navigatorKey
}

@pragma('vm:entry-point')
void _onBackgroundResponse(NotificationResponse response) {}
