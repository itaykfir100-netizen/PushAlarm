import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'app_keys.dart';
import 'data/database_helper.dart';
import 'models/alarm.dart';
import 'providers/alarms_provider.dart';
import 'providers/stats_provider.dart';
import 'screens/alarms/alarms_screen.dart';
import 'screens/stats/stats_screen.dart';
import 'screens/workout/workout_screen.dart';
import 'services/alarm_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Wire up the Kotlin → Dart MethodChannel (alarmFired, etc.)
  AlarmService.instance.setup();

  await _requestPermissions();

  // Check if the alarm fired while the app was closed.
  // AlarmForegroundService writes the alarm ID to native AlarmPrefs.
  final activeAlarmId = await AlarmService.instance.getActiveAlarmId();
  Alarm? pendingAlarm;
  if (activeAlarmId != null) {
    pendingAlarm = await DatabaseHelper.instance.getAlarm(activeAlarmId);
  }

  runApp(PushAlarmApp(pendingAlarm: pendingAlarm));
}

Future<void> _requestPermissions() async {
  await [
    Permission.notification,
    Permission.camera,
    Permission.scheduleExactAlarm,
  ].request();
}

class PushAlarmApp extends StatefulWidget {
  const PushAlarmApp({super.key, this.pendingAlarm});
  final Alarm? pendingAlarm;

  @override
  State<PushAlarmApp> createState() => _PushAlarmAppState();
}

class _PushAlarmAppState extends State<PushAlarmApp> {
  @override
  void initState() {
    super.initState();
    // If an alarm was waiting when the app cold-started, push WorkoutScreen
    // on top of HomeScreen after the first frame so there's always a back
    // route to return to (fixes the black-screen-after-done bug).
    if (widget.pendingAlarm != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigatorKey.currentState
            ?.pushNamed('/workout', arguments: widget.pendingAlarm!.id!);
      });
    }
  }

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
        navigatorKey: navigatorKey,
        home: const HomeScreen(),
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
