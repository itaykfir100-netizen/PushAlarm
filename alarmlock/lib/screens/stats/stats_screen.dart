import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/stats_provider.dart';
import '../../theme/app_theme.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StatsProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StatsProvider>(
      builder: (context, stats, _) {
        return Scaffold(
          backgroundColor: kBackground,
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                const Text(
                  'Stats',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),

                // Top stat cards row
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Total Push-Ups',
                        value: stats.totalPushUps.toString(),
                        icon: Icons.fitness_center,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'Sessions',
                        value: stats.totalSessions.toString(),
                        icon: Icons.alarm_on,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Current Streak',
                        value: '${stats.currentStreak} days',
                        icon: Icons.local_fire_department,
                        iconColor: const Color(0xFFFF9500),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'Best Streak',
                        value: '${stats.bestStreak} days',
                        icon: Icons.emoji_events,
                        iconColor: const Color(0xFFFFCC00),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _StatCard(
                  label: 'Avg per session',
                  value: stats.avgPushUps.toStringAsFixed(1),
                  icon: Icons.show_chart,
                  wide: true,
                ),
                const SizedBox(height: 24),

                // Weekly bar chart
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: kCard,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Last 7 Days',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 180,
                        child: _WeeklyChart(bars: stats.weeklyBars),
                      ),
                    ],
                  ),
                ),

                if (stats.totalSessions == 0) ...[
                  const SizedBox(height: 40),
                  const Center(
                    child: Text(
                      'No workouts yet.\nComplete your first alarm to see stats.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 15),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.iconColor = kGreen,
    this.wide = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 12, letterSpacing: 0.3)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  const _WeeklyChart({required this.bars});
  final List<double> bars;

  @override
  Widget build(BuildContext context) {
    final maxY = bars.isEmpty ? 10.0 : (bars.reduce((a, b) => a > b ? a : b) + 5);
    final now = DateTime.now();
    final dayLabels = List.generate(
      7,
      (i) => DateFormat('E').format(now.subtract(Duration(days: 6 - i)))[0],
    );

    return BarChart(
      BarChartData(
        maxY: maxY,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, _) {
                final i = val.toInt();
                if (i < 0 || i >= dayLabels.length) return const SizedBox();
                final isToday = i == 6;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    dayLabels[i],
                    style: TextStyle(
                      color: isToday ? kGreen : Colors.grey,
                      fontSize: 12,
                      fontWeight:
                          isToday ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: Colors.white10, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(
          7,
          (i) => BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: bars[i],
                color: i == 6 ? kGreen : kGreen.withValues(alpha: 0.5),
                width: 24,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxY,
                  color: kSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
