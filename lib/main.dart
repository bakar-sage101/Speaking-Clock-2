import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'platform/reliability_platform.dart';

void main() => runApp(const SpeakingClockApp());

class AppColors {
  static const canvas = Color(0xfff7f7f3);
  static const ink = Color(0xff18211b);
  static const sage = Color(0xff5f7f67);
  static const sageLight = Color(0xffe6eee7);
  static const blue = Color(0xff87a8b0);
  static const amber = Color(0xffc88945);
  static const amberLight = Color(0xfffff2df);
  static const line = Color(0xffe6e8e4);
}

enum ReminderType { water, breakTime, meeting, medication, custom }

class Reminder {
  const Reminder({
    required this.title,
    required this.time,
    required this.detail,
    required this.type,
    this.isAlarm = false,
  });

  final String title;
  final String time;
  final String detail;
  final ReminderType type;
  final bool isAlarm;

  Map<String, Object> toJson() => {
        'title': title,
        'time': time,
        'detail': detail,
        'type': type.index,
        'isAlarm': isAlarm,
      };

  factory Reminder.fromJson(Map<String, dynamic> json) => Reminder(
        title: json['title'] as String,
        time: json['time'] as String,
        detail: json['detail'] as String,
        type: ReminderType.values[json['type'] as int],
        isAlarm: json['isAlarm'] as bool? ?? false,
      );
}

class SpeakingClockApp extends StatefulWidget {
  const SpeakingClockApp({super.key});

  @override
  State<SpeakingClockApp> createState() => _SpeakingClockAppState();
}

class _SpeakingClockAppState extends State<SpeakingClockApp> {
  var _tab = 0;
  var _darkMode = false;
  List<Reminder> _reminders = [
    const Reminder(
      title: 'Drink water',
      time: '10:30',
      detail: 'Every 90 minutes · Gentle reminder',
      type: ReminderType.water,
    ),
    const Reminder(
      title: 'Design review',
      time: '11:00',
      detail: 'Google Meet · 10 minutes before',
      type: ReminderType.meeting,
      isAlarm: true,
    ),
    const Reminder(
      title: 'Stand and stretch',
      time: '12:00',
      detail: 'Weekdays · Every 2 hours',
      type: ReminderType.breakTime,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString('reminders');
    if (raw == null || !mounted) return;

    try {
      final saved = (jsonDecode(raw) as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(Reminder.fromJson)
          .toList();
      setState(() => _reminders = saved);
    } on FormatException {
      await preferences.remove('reminders');
    }
  }

  Future<void> _saveReminders() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      'reminders',
      jsonEncode(_reminders.map((reminder) => reminder.toJson()).toList()),
    );
  }

  Future<void> _showAddReminder() async {
    final reminder = await showModalBottomSheet<Reminder>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ReminderEditor(),
    );
    if (reminder != null) {
      setState(() => _reminders = [..._reminders, reminder]);
      await _saveReminders();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.sage,
      brightness: _darkMode ? Brightness.dark : Brightness.light,
    );
    return MaterialApp(
      title: 'Speaking Clock',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor:
            _darkMode ? const Color(0xff111411) : AppColors.canvas,
        fontFamily: 'Inter',
      ),
      home: Scaffold(
        body: SafeArea(
          child: IndexedStack(
            index: _tab,
            children: [
              TodayScreen(reminders: _reminders, onAdd: _showAddReminder),
              RoutinesScreen(reminders: _reminders, onAdd: _showAddReminder),
              SettingsScreen(
                darkMode: _darkMode,
                onDarkModeChanged: (value) => setState(() => _darkMode = value),
                onOpenReliability: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ReliabilityScreen(),
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: _tab == 2
            ? null
            : FloatingActionButton.extended(
                onPressed: _showAddReminder,
                backgroundColor: AppColors.sage,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add reminder'),
              ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (value) => setState(() => _tab = value),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.today_outlined),
              selectedIcon: Icon(Icons.today_rounded),
              label: 'Today',
            ),
            NavigationDestination(
              icon: Icon(Icons.repeat_rounded),
              selectedIcon: Icon(Icons.repeat_one_rounded),
              label: 'Routines',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings_rounded),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key, required this.reminders, required this.onAdd});

  final List<Reminder> reminders;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final next = reminders.first;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 108),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Good morning', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text('Friday, 10 July', style: _subtle(context)),
              ],
            ),
            const ReadinessChip(),
          ],
        ),
        const SizedBox(height: 30),
        Text('NEXT UP', style: _sectionLabel(context)),
        const SizedBox(height: 10),
        NextReminderCard(reminder: next),
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Later today', style: Theme.of(context).textTheme.titleLarge),
            TextButton(onPressed: onAdd, child: const Text('Add')),
          ],
        ),
        const SizedBox(height: 4),
        ...reminders.skip(1).map(
              (reminder) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ReminderRow(reminder: reminder),
              ),
            ),
        const SizedBox(height: 18),
        const ReliabilityNote(),
      ],
    );
  }
}

class ReadinessChip extends StatelessWidget {
  const ReadinessChip({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.amberLight,
        borderRadius: BorderRadius.circular(30),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.info_outline_rounded, size: 16, color: AppColors.amber),
          SizedBox(width: 5),
          Text('Needs setup', style: TextStyle(color: AppColors.amber, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class NextReminderCard extends StatelessWidget {
  const NextReminderCard({super.key, required this.reminder});

  final Reminder reminder;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ReminderIcon(type: reminder.type, large: true),
              IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz_rounded)),
            ],
          ),
          const SizedBox(height: 22),
          Text(reminder.time, style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(reminder.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(reminder.detail, style: _subtle(context)),
          const SizedBox(height: 20),
          FilledButton.tonalIcon(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${reminder.title} snoozed for 10 minutes')),
            ),
            icon: const Icon(Icons.snooze_rounded),
            label: const Text('Snooze 10 min'),
          ),
        ],
      ),
    );
  }
}

class ReminderRow extends StatelessWidget {
  const ReminderRow({super.key, required this.reminder});

  final Reminder reminder;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          ReminderIcon(type: reminder.type),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reminder.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(reminder.detail, style: _subtle(context, small: true)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(reminder.time, style: const TextStyle(fontWeight: FontWeight.w800)),
              if (reminder.isAlarm) const Padding(padding: EdgeInsets.only(top: 4), child: Icon(Icons.volume_up_rounded, size: 15, color: AppColors.amber)),
            ],
          ),
        ],
      ),
    );
  }
}

class ReminderIcon extends StatelessWidget {
  const ReminderIcon({super.key, required this.type, this.large = false});

  final ReminderType type;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final data = switch (type) {
      ReminderType.water => (Icons.water_drop_outlined, AppColors.blue),
      ReminderType.breakTime => (Icons.self_improvement_outlined, AppColors.sage),
      ReminderType.meeting => (Icons.videocam_outlined, AppColors.amber),
      ReminderType.medication => (Icons.medication_outlined, AppColors.amber),
      ReminderType.custom => (Icons.notifications_none_rounded, AppColors.sage),
    };
    final size = large ? 50.0 : 42.0;
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: data.$2.withValues(alpha: .16),
        borderRadius: BorderRadius.circular(large ? 16 : 13),
      ),
      child: Icon(data.$1, color: data.$2, size: large ? 26 : 22),
    );
  }
}

class ReliabilityNote extends StatelessWidget {
  const ReliabilityNote({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.sageLight, borderRadius: BorderRadius.circular(18)),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_user_outlined, color: AppColors.sage),
          SizedBox(width: 10),
          Expanded(child: Text('Set up Reliable Alarm before using it for important reminders. We will check the required device permissions for you.', style: TextStyle(height: 1.35))),
        ],
      ),
    );
  }
}

class RoutinesScreen extends StatelessWidget {
  const RoutinesScreen({super.key, required this.reminders, required this.onAdd});

  final List<Reminder> reminders;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 108),
      children: [
        Text('Routines', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 7),
        Text('Small prompts for a better workday.', style: _subtle(context)),
        const SizedBox(height: 28),
        Text('QUICK START', style: _sectionLabel(context)),
        const SizedBox(height: 10),
        const Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            RoutinePreset(icon: Icons.water_drop_outlined, label: 'Drink water'),
            RoutinePreset(icon: Icons.visibility_outlined, label: 'Eye break'),
            RoutinePreset(icon: Icons.self_improvement_outlined, label: 'Stretch'),
            RoutinePreset(icon: Icons.directions_walk_outlined, label: 'Walk'),
          ],
        ),
        const SizedBox(height: 30),
        Text('YOUR ROUTINES', style: _sectionLabel(context)),
        const SizedBox(height: 10),
        ...reminders.where((item) => item.type != ReminderType.meeting).map((item) => Padding(padding: const EdgeInsets.only(bottom: 10), child: ReminderRow(reminder: item))),
        const SizedBox(height: 10),
        OutlinedButton.icon(onPressed: onAdd, icon: const Icon(Icons.add_rounded), label: const Text('Create a custom routine')),
      ],
    );
  }
}

class RoutinePreset extends StatelessWidget {
  const RoutinePreset({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 152,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: AppColors.sage), const SizedBox(height: 16), Text(label, style: const TextStyle(fontWeight: FontWeight.w800))]),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.darkMode,
    required this.onDarkModeChanged,
    required this.onOpenReliability,
  });

  final bool darkMode;
  final ValueChanged<bool> onDarkModeChanged;
  final VoidCallback onOpenReliability;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 36),
      children: [
        Text('Settings', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 28),
        Text('RELIABILITY', style: _sectionLabel(context)),
        const SizedBox(height: 10),
        SettingTile(icon: Icons.verified_user_outlined, title: 'Reliable Alarm', subtitle: 'Finish setup on this device', onTap: onOpenReliability),
        const SizedBox(height: 10),
        const SettingTile(icon: Icons.calendar_month_outlined, title: 'Google Calendar', subtitle: 'Connect your meetings'),
        const SizedBox(height: 30),
        Text('PREFERENCES', style: _sectionLabel(context)),
        const SizedBox(height: 10),
        Material(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          child: SwitchListTile.adaptive(
            value: darkMode,
            onChanged: onDarkModeChanged,
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('Dark mode', style: TextStyle(fontWeight: FontWeight.w800)),
            subtitle: const Text('Use a calmer dark appearance'),
          ),
        ),
        const SizedBox(height: 10),
        const SettingTile(icon: Icons.volume_up_outlined, title: 'Voice and sound', subtitle: 'System voice · Gentle chime'),
        const SizedBox(height: 30),
        Text('ACCOUNT', style: _sectionLabel(context)),
        const SizedBox(height: 10),
        const SettingTile(icon: Icons.person_outline_rounded, title: 'Sign in to sync', subtitle: 'Keep reminders across your devices'),
      ],
    );
  }
}

class SettingTile extends StatelessWidget {
  const SettingTile({super.key, required this.icon, required this.title, required this.subtitle, this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: ListTile(
        leading: Icon(icon, color: AppColors.sage),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}

class ReliabilityScreen extends StatefulWidget {
  const ReliabilityScreen({super.key});

  @override
  State<ReliabilityScreen> createState() => _ReliabilityScreenState();
}

class _ReliabilityScreenState extends State<ReliabilityScreen> with WidgetsBindingObserver {
  AlarmReadiness? _readiness;
  Object? _error;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final readiness = await ReliabilityPlatform.getStatus();
      if (mounted) setState(() => _readiness = readiness);
    } on Object catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _perform(Future<void> Function() action) async {
    await action();
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final ready = _readiness?.isReady ?? false;
    return Scaffold(
      appBar: AppBar(title: const Text('Reliable Alarm')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: ready ? AppColors.sageLight : AppColors.amberLight,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(ready ? Icons.verified_rounded : Icons.info_outline_rounded, color: ready ? AppColors.sage : AppColors.amber, size: 28),
                      const SizedBox(height: 12),
                      Text(ready ? 'Reliable Alarm is ready' : 'Finish setup for Reliable Alarm', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Text(ready ? 'Important reminders can use Android’s alarm channel and spoken voice.' : 'Complete each item below before relying on a spoken alarm.'),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                if (_error != null) Text('Unable to read device status: $_error'),
                _ReadinessItem(
                  title: 'Notifications',
                  detail: 'Allow Speaking Clock notifications',
                  ready: _readiness?.notificationsEnabled ?? false,
                  action: () => _perform(ReliabilityPlatform.requestNotifications),
                  actionLabel: 'Allow',
                ),
                _ReadinessItem(
                  title: 'Exact alarms',
                  detail: 'Let important alarms fire at their exact time',
                  ready: _readiness?.exactAlarmEnabled ?? false,
                  action: () => _perform(ReliabilityPlatform.requestExactAlarms),
                  actionLabel: 'Allow',
                ),
                _ReadinessItem(
                  title: 'Do Not Disturb',
                  detail: 'Allow alarm behavior during Do Not Disturb',
                  ready: _readiness?.dndPolicyAccess ?? false,
                  action: () => _perform(ReliabilityPlatform.openDndSettings),
                  actionLabel: 'Open settings',
                ),
                _ReadinessItem(
                  title: 'Alarm volume',
                  detail: 'Keep alarm volume above zero',
                  ready: _readiness?.alarmVolumeEnabled ?? false,
                  action: _refresh,
                  actionLabel: 'Check again',
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(onPressed: _refresh, icon: const Icon(Icons.refresh_rounded), label: const Text('Refresh device status')),
              ],
            ),
    );
  }
}

class _ReadinessItem extends StatelessWidget {
  const _ReadinessItem({required this.title, required this.detail, required this.ready, required this.action, required this.actionLabel});

  final String title;
  final String detail;
  final bool ready;
  final VoidCallback action;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        child: ListTile(
          leading: Icon(ready ? Icons.check_circle_rounded : Icons.circle_outlined, color: ready ? AppColors.sage : AppColors.amber),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(detail),
          trailing: ready ? const Text('Ready', style: TextStyle(color: AppColors.sage, fontWeight: FontWeight.w800)) : TextButton(onPressed: action, child: Text(actionLabel)),
        ),
      ),
    );
  }
}

class ReminderEditor extends StatefulWidget {
  const ReminderEditor({super.key});

  @override
  State<ReminderEditor> createState() => _ReminderEditorState();
}

class _ReminderEditorState extends State<ReminderEditor> {
  final _controller = TextEditingController();
  var _type = ReminderType.water;
  var _isAlarm = false;
  var _frequency = 'Every day';
  var _time = const TimeOfDay(hour: 10, minute: 30);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  void _save() {
    final title = _controller.text.trim().isEmpty ? 'Drink water' : _controller.text.trim();
    Navigator.pop(
      context,
      Reminder(
        title: title,
        time: _time.format(context),
        detail: '$_frequency · ${_isAlarm ? 'Reliable Alarm' : 'Gentle reminder'}',
        type: _type,
        isAlarm: _isAlarm,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.viewInsetsOf(context).bottom + 22),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(height: 4, width: 40, decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 22),
              Text('New reminder', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 18),
              TextField(controller: _controller, autofocus: true, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'What should we remind you?', hintText: 'Drink water', border: OutlineInputBorder())),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ReminderType.values.map((type) => ChoiceChip(label: Text(_label(type)), selected: type == _type, onSelected: (_) => setState(() => _type = type))).toList(),
              ),
              const SizedBox(height: 18),
              Row(children: [
                Expanded(child: OutlinedButton.icon(onPressed: _pickTime, icon: const Icon(Icons.schedule_outlined), label: Text(_time.format(context)))),
                const SizedBox(width: 10),
                Expanded(child: DropdownButtonFormField<String>(initialValue: _frequency, decoration: const InputDecoration(labelText: 'Repeat', border: OutlineInputBorder()), items: const ['Once', 'Every day', 'Weekdays', 'Every 90 min'].map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(), onChanged: (value) => setState(() => _frequency = value ?? _frequency))),
              ]),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(color: AppColors.sageLight, borderRadius: BorderRadius.circular(16)),
                child: SwitchListTile.adaptive(value: _isAlarm, onChanged: (value) => setState(() => _isAlarm = value), secondary: const Icon(Icons.volume_up_outlined, color: AppColors.amber), title: const Text('Reliable Alarm', style: TextStyle(fontWeight: FontWeight.w800)), subtitle: const Text('Use spoken alarm for important reminders')),
              ),
              const SizedBox(height: 18),
              SizedBox(width: double.infinity, child: FilledButton(onPressed: _save, child: const Text('Save reminder'))),
            ],
          ),
        ),
      ),
    );
  }
}

TextStyle _sectionLabel(BuildContext context) => Theme.of(context).textTheme.labelMedium!.copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurfaceVariant);
TextStyle _subtle(BuildContext context, {bool small = false}) => (small ? Theme.of(context).textTheme.bodySmall : Theme.of(context).textTheme.bodyMedium)!.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);

String _label(ReminderType type) => switch (type) {
      ReminderType.water => 'Water',
      ReminderType.breakTime => 'Break',
      ReminderType.meeting => 'Meeting',
      ReminderType.medication => 'Medication',
      ReminderType.custom => 'Custom',
    };
