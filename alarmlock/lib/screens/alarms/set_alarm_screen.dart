import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/alarm.dart';
import '../../providers/alarms_provider.dart';
import '../../theme/app_theme.dart';

class SetAlarmScreen extends StatefulWidget {
  const SetAlarmScreen({super.key, this.existing});
  final Alarm? existing;

  @override
  State<SetAlarmScreen> createState() => _SetAlarmScreenState();
}

class _SetAlarmScreenState extends State<SetAlarmScreen> {
  late int _hour;
  late int _minute;
  late List<bool> _days;
  late int _pushUps;
  late TextEditingController _labelCtrl;

  @override
  void initState() {
    super.initState();
    final a = widget.existing;
    _hour = a?.hour ?? TimeOfDay.now().hour;
    _minute = a?.minute ?? TimeOfDay.now().minute;
    _days = a != null ? List.from(a.days) : List.filled(7, false);
    _pushUps = a?.pushUpCount ?? 10;
    _labelCtrl = TextEditingController(text: a?.label ?? '');
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: kBackground,
        title: Text(
          isEdit ? 'Edit Alarm' : 'New Alarm',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: kGreen)),
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save',
                style: TextStyle(color: kGreen, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Time picker
          GestureDetector(
            onTap: _pickTime,
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _formatTime(),
                style: const TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.w200,
                  color: Colors.white,
                  letterSpacing: -2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Day selector
          _Section(
            title: 'Repeat',
            child: _DaySelector(
              days: _days,
              onChanged: (i, val) => setState(() => _days[i] = val),
            ),
          ),
          const SizedBox(height: 16),

          // Push-up count
          _Section(
            title: 'Push-ups required',
            child: Column(
              children: [
                Text(
                  '$_pushUps',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: kGreen,
                  ),
                ),
                Slider(
                  value: _pushUps.toDouble(),
                  min: 1,
                  max: 100,
                  divisions: 99,
                  activeColor: kGreen,
                  inactiveColor: kSurface,
                  label: '$_pushUps reps',
                  onChanged: (v) => setState(() => _pushUps = v.round()),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _QuickPick(label: '5', onTap: () => setState(() => _pushUps = 5)),
                    _QuickPick(label: '10', onTap: () => setState(() => _pushUps = 10)),
                    _QuickPick(label: '20', onTap: () => setState(() => _pushUps = 20)),
                    _QuickPick(label: '30', onTap: () => setState(() => _pushUps = 30)),
                    _QuickPick(label: '50', onTap: () => setState(() => _pushUps = 50)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Label
          _Section(
            title: 'Label',
            child: TextField(
              controller: _labelCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'e.g. Weekday Grind',
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
              ),
            ),
          ),

          if (isEdit) ...[
            const SizedBox(height: 24),
            TextButton(
              onPressed: _delete,
              child: const Text(
                'Delete Alarm',
                style: TextStyle(color: Color(0xFFFF3B30), fontSize: 16),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime() {
    final h = _hour % 12 == 0 ? 12 : _hour % 12;
    final m = _minute.toString().padLeft(2, '0');
    final period = _hour < 12 ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _hour, minute: _minute),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(primary: kGreen),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _hour = picked.hour;
        _minute = picked.minute;
      });
    }
  }

  Future<void> _save() async {
    final provider = context.read<AlarmsProvider>();
    final alarm = Alarm(
      id: widget.existing?.id,
      hour: _hour,
      minute: _minute,
      label: _labelCtrl.text.trim(),
      days: _days,
      pushUpCount: _pushUps,
      isEnabled: widget.existing?.isEnabled ?? true,
    );

    if (widget.existing == null) {
      await provider.addAlarm(alarm);
    } else {
      await provider.updateAlarm(alarm);
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kCard,
        title: const Text('Delete alarm?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete',
                  style: TextStyle(color: Color(0xFFFF3B30)))),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      final nav = Navigator.of(context);
      await context.read<AlarmsProvider>().deleteAlarm(widget.existing!.id!);
      nav.pop();
    }
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.grey, fontSize: 13, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _DaySelector extends StatelessWidget {
  const _DaySelector({required this.days, required this.onChanged});
  final List<bool> days;
  final void Function(int, bool) onChanged;

  static const _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        return GestureDetector(
          onTap: () => onChanged(i, !days[i]),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: days[i] ? kGreen : kSurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _labels[i],
              style: TextStyle(
                color: days[i] ? Colors.black : Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _QuickPick extends StatelessWidget {
  const _QuickPick({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: const TextStyle(color: Colors.white, fontSize: 13)),
      ),
    );
  }
}
