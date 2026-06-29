import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/alarm.dart';
import '../../providers/alarms_provider.dart';
import '../../theme/app_theme.dart';
import 'set_alarm_screen.dart';

class AlarmsScreen extends StatelessWidget {
  const AlarmsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AlarmsProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: kBackground,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Alarms',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _openSetAlarm(context, null),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('New'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kGreen,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          shape: const StadiumBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: provider.alarms.isEmpty
                      ? const Center(
                          child: Text(
                            'No alarms yet.\nTap + New to add one.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                          itemCount: provider.alarms.length,
                          separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                          itemBuilder: (context, i) =>
                              _AlarmCard(alarm: provider.alarms[i]),
                        ),
                ),
                // Simulate button
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: OutlinedButton(
                    onPressed: () => _simulate(context, provider),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFF3B30),
                      side: const BorderSide(color: Color(0xFFFF3B30)),
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Simulate Alarm Firing →'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openSetAlarm(BuildContext context, Alarm? alarm) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SetAlarmScreen(existing: alarm)),
    );
  }

  Future<void> _simulate(BuildContext context, AlarmsProvider provider) async {
    final alarms = provider.alarms.where((a) => a.isEnabled).toList();
    if (alarms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enable at least one alarm first.')),
      );
      return;
    }
    final alarm = alarms.first;
    Navigator.pushNamed(context, '/workout', arguments: alarm.id);
  }
}

class _AlarmCard extends StatelessWidget {
  const _AlarmCard({required this.alarm});
  final Alarm alarm;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AlarmsProvider>();
    return Dismissible(
      key: ValueKey(alarm.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFFF3B30),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => provider.deleteAlarm(alarm.id!),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SetAlarmScreen(existing: alarm)),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      alarm.timeString,
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w300,
                        color: alarm.isEnabled ? Colors.white : Colors.grey,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Switch(
                        value: alarm.isEnabled,
                        onChanged: (_) => provider.toggleAlarm(alarm),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: alarm.isEnabled
                              ? kGreen.withValues(alpha: 0.2)
                              : kSurface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${alarm.pushUpCount} reps',
                          style: TextStyle(
                            color: alarm.isEnabled ? kGreen : Colors.grey,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (alarm.label.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    alarm.label,
                    style: TextStyle(
                      color: alarm.isEnabled ? Colors.white70 : Colors.grey,
                      fontSize: 15,
                    ),
                  ),
                ),
              const SizedBox(height: 4),
              _DayChips(days: alarm.days, enabled: alarm.isEnabled),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayChips extends StatelessWidget {
  const _DayChips({required this.days, required this.enabled});
  final List<bool> days;
  final bool enabled;

  static const _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(7, (i) {
        final active = days[i];
        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active && enabled ? kGreen : kSurface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _labels[i],
              style: TextStyle(
                color: active && enabled ? Colors.black : Colors.grey,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        );
      }),
    );
  }
}
