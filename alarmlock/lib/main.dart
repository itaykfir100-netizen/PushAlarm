import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'data/database_helper.dart';
import 'models/alarm.dart';
import 'providers/alarms_provider.dart';
import 'providers/stats_provider.dart';
import 'screens/alarms/alarms_screen.dart';
import 'screens/stats/stats_screen.dart';
import 'screens/workout/workout_screen.dart';
import 'services/alarm_service.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService.instance.initialize();
  await AlarmService.instance.init();

  // Request permissions on first run
  await _requestPermissions();

  // Check if there is an alarm waiting to be completed
  final activeAlarmId = await AlarmService.instance.getActiveAlarmId();
  Alarm? activeAlarm;
  if (activeAlarmId != null) {
    activeAlarm = await DatabaseHelper.instance.getAlarm(activeAlarmId);
  }

  runApp(PushAlarmApp(pendingAlarm: activeAlarm));
}

Future<void> _requestPermissions() async {
  await [
    Permission.notification,
    Permission.camera,
    Permission.scheduleExactAlarm,
  ].request();
}

class PushAlarmApp extends StatelessWidget {
  const PushAlarmApp({super.key, this.pendingAlarm});
  final Alarm? pendingAlarm;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AlarmsProvider()..load()),
        ChangeNotifierProvider(create: (_) => StatsProvider()..load()),
      ],
      child: MaterialApp(
        title: 'PushUp Alarm',
        theme: appTheme,
        debugShowCheckedModeBanner: false,
        home: pendingAlarm != null
            ? WorkoutScreen(
                alarmId: pendingAlarm!.id!,
                target: pendingAlarm!.pushUpCount,
              )
            : const HomeScreen(),
        onGenerateRoute: (settings) {
          if (settings.name == '/workout') {
            final alarmId = settings.arguments as int;
            return MaterialPageRoute(
              builder: (_) => FutureBuilder<Alarm?>(
                future: DatabaseHelper.instance.getAlarm(alarmId),
                builder: (ctx, snap) {
                  if (!snap.hasData) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final alarm = snap.data!;
                  return WorkoutScreen(
                    alarmId: alarm.id!,
                    target: alarm.pushUpCount,
                  );
                },
              ),
            );
          }
          return null;
        },
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  static const _screens = [AlarmsScreen(), StatsScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_tab],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.alarm),
            label: 'Alarms',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Stats',
          ),
        ],
      ),
    );
  }
}
