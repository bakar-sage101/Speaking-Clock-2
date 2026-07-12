import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data/app_database.dart';
import 'data/app_preferences.dart';
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

enum DeliveryMode { gentle, alarm, speaking }

enum ToneOption { softChime, classicAlarm, digitalBeep, morningBell, calmWater, vibrationOnly }

class Reminder {
  const Reminder({
    required this.id,
    required this.title,
    required this.time,
    required this.detail,
    required this.type,
    this.deliveryMode = DeliveryMode.gentle,
    this.spokenMessage = '',
    this.tone = ToneOption.softChime,
    this.enabled = true,
    this.snoozeMinutes = 10,
    this.triggerAtMillis,
    this.createdAtMillis,
    this.updatedAtMillis,
  });

  final String id;
  final String title;
  final String time;
  final String detail;
  final ReminderType type;
  final DeliveryMode deliveryMode;
  final String spokenMessage;
  final ToneOption tone;
  final bool enabled;
  final int snoozeMinutes;
  final int? triggerAtMillis;
  final int? createdAtMillis;
  final int? updatedAtMillis;

  bool get isAlarm => deliveryMode != DeliveryMode.gentle;
  bool get isSpeakingAlarm => deliveryMode == DeliveryMode.speaking;

  Reminder copyWith({
    String? title,
    String? time,
    String? detail,
    ReminderType? type,
    DeliveryMode? deliveryMode,
    String? spokenMessage,
    ToneOption? tone,
    bool? enabled,
    int? snoozeMinutes,
    int? triggerAtMillis,
    int? updatedAtMillis,
  }) =>
      Reminder(
        id: id,
        title: title ?? this.title,
        time: time ?? this.time,
        detail: detail ?? this.detail,
        type: type ?? this.type,
        deliveryMode: deliveryMode ?? this.deliveryMode,
        spokenMessage: spokenMessage ?? this.spokenMessage,
        tone: tone ?? this.tone,
        enabled: enabled ?? this.enabled,
        snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
        triggerAtMillis: triggerAtMillis ?? this.triggerAtMillis,
        createdAtMillis: createdAtMillis,
        updatedAtMillis: updatedAtMillis ?? this.updatedAtMillis,
      );

  ReminderRecordsCompanion toCompanion() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return ReminderRecordsCompanion(
      id: Value(id),
      title: Value(title),
      detail: Value(detail),
      type: Value(type.index),
      deliveryMode: Value(deliveryMode.name),
      spokenMessage: Value(spokenMessage),
      toneId: Value(tone.name),
      enabled: Value(enabled),
      snoozeMinutes: Value(snoozeMinutes),
      timeLabel: Value(time),
      triggerAtMillis: Value(triggerAtMillis),
      createdAtMillis: Value(createdAtMillis ?? now),
      updatedAtMillis: Value(now),
    );
  }

  factory Reminder.fromRecord(ReminderRecord record) => Reminder(
        id: record.id,
        title: record.title,
        time: record.timeLabel,
        detail: record.detail,
        type: _enumValue(ReminderType.values, record.type, ReminderType.custom),
        deliveryMode: _deliveryModeFromName(record.deliveryMode),
        spokenMessage: record.spokenMessage,
        tone: _toneFromName(record.toneId),
        enabled: record.enabled,
        snoozeMinutes: record.snoozeMinutes,
        triggerAtMillis: record.triggerAtMillis,
        createdAtMillis: record.createdAtMillis,
        updatedAtMillis: record.updatedAtMillis,
      );
}

class SpeakingClockApp extends StatefulWidget {
  const SpeakingClockApp({super.key});

  @override
  State<SpeakingClockApp> createState() => _SpeakingClockAppState();
}

class _SpeakingClockAppState extends State<SpeakingClockApp> with WidgetsBindingObserver {
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  late final AppDatabase _database;
  var _tab = 0;
  var _darkMode = false;
  bool? _onboardingComplete;
  AlarmReadiness? _readiness;
  List<Reminder> _reminders = [
    const Reminder(
      id: 'water-1030',
      title: 'Drink water',
      time: '10:30',
      detail: 'Every 90 min · Gentle reminder',
      type: ReminderType.water,
    ),
    const Reminder(
      id: 'meeting-1100',
      title: 'Design review',
      time: '11:00',
      detail: 'Google Meet · 10 minutes before',
      type: ReminderType.meeting,
      deliveryMode: DeliveryMode.speaking,
      spokenMessage: 'Design review starts soon.',
      tone: ToneOption.morningBell,
    ),
    const Reminder(
      id: 'stretch-1200',
      title: 'Stand and stretch',
      time: '12:00',
      detail: 'Weekdays · Every 2 hours',
      type: ReminderType.breakTime,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _database = AppDatabase.open();
    _loadOnboardingState();
    _loadReminders();
    _refreshReadiness();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshReadiness();
  }

  Future<void> _loadOnboardingState() async {
    final complete = await AppPreferences.isOnboardingComplete();
    if (mounted) setState(() => _onboardingComplete = complete);
  }

  Future<void> _loadReminders() async {
    final saved = await _database.allReminders();
    if (!mounted) return;
    if (saved.isEmpty) {
      await Future.wait(_reminders.map((reminder) => _database.saveReminder(reminder.toCompanion())));
      return;
    }
    setState(() => _reminders = _sortReminders(saved.map(Reminder.fromRecord).toList()));
  }

  Future<void> _refreshReadiness() async {
    try {
      final readiness = await ReliabilityPlatform.getStatus();
      if (mounted) setState(() => _readiness = readiness);
    } on Object {
      // Non-Android targets and early app startup can ignore readiness checks.
    }
  }

  Future<void> _finishOnboarding() async {
    await AppPreferences.setOnboardingComplete(true);
    if (!mounted) return;
    setState(() => _onboardingComplete = true);
    await _refreshReadiness();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _database.close();
    super.dispose();
  }

  Future<void> _showAddReminder({ReminderType initialType = ReminderType.water}) async {
    final reminder = await showModalBottomSheet<Reminder>(
      context: _navigatorKey.currentState!.context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReminderEditor(initialType: initialType),
    );
    if (reminder != null) {
      setState(() => _reminders = _sortReminders([..._reminders, reminder]));
      await _database.saveReminder(reminder.toCompanion());
      await _scheduleDeviceReminder(reminder);
      await _refreshReadiness();
    }
  }

  Future<void> _editReminder(Reminder original) async {
    final updated = await showModalBottomSheet<Reminder>(
      context: _navigatorKey.currentState!.context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReminderEditor(initialType: original.type, reminder: original),
    );
    if (updated == null) return;
    await _cancelDeviceReminder(original);
    setState(() {
      _reminders = _sortReminders([
        for (final reminder in _reminders)
          if (reminder.id == updated.id) updated else reminder,
      ]);
    });
    await _database.saveReminder(updated.toCompanion());
    await _scheduleDeviceReminder(updated);
  }

  Future<void> _deleteReminder(Reminder reminder) async {
    await _cancelDeviceReminder(reminder);
    setState(() => _reminders = _sortReminders(_reminders.where((item) => item.id != reminder.id).toList()));
    await _database.deleteReminderById(reminder.id);
    _navigatorKey.currentState?.pop();
    _messengerKey.currentState?.showSnackBar(SnackBar(content: Text('${reminder.title} deleted.')));
  }

  Future<void> _toggleReminder(Reminder reminder, bool enabled) async {
    if (!enabled) await _cancelDeviceReminder(reminder);
    final updated = reminder.copyWith(enabled: enabled, updatedAtMillis: DateTime.now().millisecondsSinceEpoch);
    setState(() {
      _reminders = _sortReminders([
        for (final item in _reminders)
          if (item.id == reminder.id) updated else item,
      ]);
    });
    await _database.setReminderEnabled(reminder.id, enabled);
    if (enabled) await _scheduleDeviceReminder(updated);
    _messengerKey.currentState?.showSnackBar(
      SnackBar(content: Text('${reminder.title} ${enabled ? 'resumed' : 'paused'}.')),
    );
  }

  void _openReminderDetails(Reminder reminder) {
    _navigatorKey.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => ReminderDetailScreen(
          reminder: reminder,
          onEdit: () => _editReminder(reminder),
          onDelete: () => _deleteReminder(reminder),
          onToggleEnabled: (enabled) => _toggleReminder(reminder, enabled),
        ),
      ),
    );
  }

  Future<void> _scheduleDeviceReminder(Reminder reminder) async {
    if (!reminder.enabled || reminder.triggerAtMillis == null) return;
    try {
      final readiness = await ReliabilityPlatform.getStatus();
      final canSchedule = reminder.isSpeakingAlarm
          ? readiness.canScheduleSpokenAlarms
          : readiness.canScheduleAlarms;
      if (!canSchedule) {
        if (mounted) {
          _messengerKey.currentState?.showSnackBar(
            SnackBar(
              content: Text(
                reminder.isAlarm
                    ? 'Reminder saved. Finish notification, exact alarm, and alarm volume setup before it can speak.'
                    : 'Reminder saved. Allow notifications and exact alarms before it can fire.',
              ),
            ),
          );
        }
        return;
      }
      await ReliabilityPlatform.scheduleAlarm(
        id: reminder.id.hashCode & 0x7fffffff,
        triggerAt: DateTime.fromMillisecondsSinceEpoch(reminder.triggerAtMillis!),
        title: reminder.title,
        alarmStyle: reminder.isAlarm,
        spoken: reminder.isSpeakingAlarm,
        spokenMessage: reminder.spokenMessage,
        toneId: reminder.tone.name,
        snoozeMinutes: reminder.snoozeMinutes,
        repeatRule: _repeatRule(reminder),
      );
      if (mounted) {
        final dndNote = reminder.isAlarm && !readiness.dndPolicyAccess
            ? ' Turn on DND access if you want it to break through Do Not Disturb.'
            : '';
        _messengerKey.currentState?.showSnackBar(
          SnackBar(content: Text('${_deliveryLabel(reminder.deliveryMode)} scheduled.$dndNote')),
        );
      }
    } on PlatformException catch (error) {
      if (mounted) {
        _messengerKey.currentState?.showSnackBar(
          SnackBar(content: Text(error.message ?? 'Reliable Alarm could not be scheduled.')),
        );
      }
    } on MissingPluginException {
      if (mounted) {
        _messengerKey.currentState?.showSnackBar(
          const SnackBar(content: Text('Reliable Alarm is not available on this platform yet.')),
        );
      }
    }
  }

  Future<void> _cancelDeviceReminder(Reminder reminder) async {
    try {
      await ReliabilityPlatform.cancelAlarm(id: reminder.id.hashCode & 0x7fffffff);
    } on PlatformException {
      // The local database is still the source of truth if Android cancellation fails.
    } on MissingPluginException {
      // Non-Android targets do not have the native alarm bridge yet.
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
      navigatorKey: _navigatorKey,
      scaffoldMessengerKey: _messengerKey,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor:
            _darkMode ? const Color(0xff111411) : AppColors.canvas,
        fontFamily: 'Inter',
      ),
      home: _onboardingComplete == null
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : !_onboardingComplete!
              ? OnboardingScreen(onComplete: _finishOnboarding)
              : Scaffold(
        body: SafeArea(
          child: IndexedStack(
            index: _tab,
            children: [
              TodayScreen(
                reminders: _reminders,
                onAdd: _showAddReminder,
                onOpenReminder: _openReminderDetails,
                readiness: _readiness,
              ),
              RoutinesScreen(
                reminders: _reminders,
                onAdd: _showAddReminder,
                onAddForType: (type) => _showAddReminder(initialType: type),
                onOpenReminder: _openReminderDetails,
              ),
              SettingsScreen(
                darkMode: _darkMode,
                onDarkModeChanged: (value) => setState(() => _darkMode = value),
                onOpenReliability: () => _navigatorKey.currentState!.push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ReliabilityScreen(),
                  ),
                ).then((_) => _refreshReadiness()),
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

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onComplete});

  final Future<void> Function() onComplete;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with WidgetsBindingObserver {
  final _controller = PageController();
  AlarmReadiness? _readiness;
  var _page = 0;
  var _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    try {
      final readiness = await ReliabilityPlatform.getStatus();
      if (mounted) setState(() => _readiness = readiness);
    } on Object {
      // Keep onboarding usable on platforms that do not have the Android bridge yet.
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _loading = true);
    try {
      await action();
      await _refresh();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _next() {
    if (_page == _pages.length - 1) {
      widget.onComplete();
      return;
    }
    _controller.nextPage(duration: const Duration(milliseconds: 260), curve: Curves.easeOutCubic);
  }

  List<_OnboardingPage> get _pages => [
        _OnboardingPage(
          icon: Icons.waving_hand_outlined,
          title: 'Welcome to Speaking Clock',
          body: 'A calm reminder app for the moments when work pulls you too deep.',
          primaryLabel: 'Start setup',
          onPrimary: _next,
        ),
        _OnboardingPage(
          icon: Icons.tune_rounded,
          title: 'Choose the right reminder strength',
          body: 'Gentle reminders are light. Alarm reminders keep ringing until acknowledged. Speaking alarms say your custom message first, then ring.',
          primaryLabel: 'Continue',
          onPrimary: _next,
        ),
        _OnboardingPage(
          icon: Icons.notifications_active_outlined,
          title: 'Allow notifications',
          body: 'Speaking Clock needs notifications so reminders can appear even when the app is not open.',
          ready: _readiness?.notificationsEnabled,
          primaryLabel: _readiness?.notificationsEnabled == true ? 'Notifications ready' : 'Allow notifications',
          onPrimary: _readiness?.notificationsEnabled == true ? _next : () => _run(ReliabilityPlatform.requestNotifications),
        ),
        _OnboardingPage(
          icon: Icons.alarm_on_rounded,
          title: 'Allow exact alarms',
          body: 'Important alarms need exact alarm access so Android lets them fire at the time you chose.',
          ready: _readiness?.exactAlarmEnabled,
          primaryLabel: _readiness?.exactAlarmEnabled == true ? 'Exact alarms ready' : 'Allow exact alarms',
          onPrimary: _readiness?.exactAlarmEnabled == true ? _next : () => _run(ReliabilityPlatform.requestExactAlarms),
        ),
        _OnboardingPage(
          icon: Icons.phone_android_rounded,
          title: 'Allow full-screen alarms',
          body: 'This lets Alarm Reminder and Speaking Alarm show the lock-screen alarm screen with Acknowledge and Snooze.',
          ready: _readiness?.fullScreenIntentEnabled,
          primaryLabel: _readiness?.fullScreenIntentEnabled == true ? 'Full-screen ready' : 'Open full-screen setting',
          onPrimary: _readiness?.fullScreenIntentEnabled == true ? _next : () => _run(ReliabilityPlatform.openFullScreenIntentSettings),
        ),
        _OnboardingPage(
          icon: Icons.do_not_disturb_on_outlined,
          title: 'Do Not Disturb behavior',
          body: 'Recommended: allow alarm behavior during Do Not Disturb. Without this, reliable alarms may stay quiet when DND is active.',
          ready: _readiness?.dndPolicyAccess,
          primaryLabel: _readiness?.dndPolicyAccess == true ? 'DND ready' : 'Open DND setting',
          onPrimary: _readiness?.dndPolicyAccess == true ? _next : () => _run(ReliabilityPlatform.openDndSettings),
          secondaryLabel: 'I will do this later',
          onSecondary: _next,
        ),
        _OnboardingPage(
          icon: Icons.volume_up_outlined,
          title: 'Check alarm volume',
          body: 'Keep alarm volume above zero. Speaking Clock can ring loudly only if Android’s alarm volume is not muted.',
          ready: _readiness?.alarmVolumeEnabled,
          primaryLabel: _readiness?.alarmVolumeEnabled == true ? 'Volume ready' : 'Check again',
          onPrimary: _readiness?.alarmVolumeEnabled == true ? _next : () => _run(_refresh),
          secondaryLabel: 'Continue anyway',
          onSecondary: _next,
        ),
        _OnboardingPage(
          icon: Icons.verified_rounded,
          title: 'You are ready',
          body: 'Create a short test alarm from the Today screen when you want to verify the lock-screen flow again.',
          primaryLabel: 'Go to Today',
          onPrimary: _next,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final pages = _pages;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: (_page + 1) / pages.length,
                      minHeight: 7,
                      borderRadius: BorderRadius.circular(99),
                      backgroundColor: AppColors.sageLight,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('${_page + 1}/${pages.length}', style: _sectionLabel(context)),
                ],
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  onPageChanged: (value) => setState(() => _page = value),
                  itemCount: pages.length,
                  itemBuilder: (context, index) => _OnboardingPageView(page: pages[index], loading: _loading),
                ),
              ),
              Row(
                children: [
                  if (_page > 0)
                    TextButton(
                      onPressed: () => _controller.previousPage(duration: const Duration(milliseconds: 220), curve: Curves.easeOutCubic),
                      child: const Text('Back'),
                    )
                  else
                    const SizedBox(width: 72),
                  const Spacer(),
                  TextButton(onPressed: widget.onComplete, child: const Text('Skip')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage {
  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.body,
    required this.primaryLabel,
    required this.onPrimary,
    this.ready,
    this.secondaryLabel,
    this.onSecondary,
  });

  final IconData icon;
  final String title;
  final String body;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final bool? ready;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
}

class _OnboardingPageView extends StatelessWidget {
  const _OnboardingPageView({required this.page, required this.loading});

  final _OnboardingPage page;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final ready = page.ready == true;
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 94,
              height: 94,
              decoration: BoxDecoration(
                color: ready ? AppColors.sageLight : AppColors.amberLight,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(ready ? Icons.check_rounded : page.icon, size: 42, color: ready ? AppColors.sage : AppColors.amber),
            ),
            const SizedBox(height: 28),
            Text(
              page.title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            Text(page.body, textAlign: TextAlign.center, style: _subtle(context)),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: loading ? null : page.onPrimary,
                child: loading ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : Text(page.primaryLabel),
              ),
            ),
            if (page.secondaryLabel != null && page.onSecondary != null) ...[
              const SizedBox(height: 8),
              TextButton(onPressed: loading ? null : page.onSecondary, child: Text(page.secondaryLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class TodayScreen extends StatelessWidget {
  const TodayScreen({
    super.key,
    required this.reminders,
    required this.onAdd,
    required this.onOpenReminder,
    required this.readiness,
  });

  final List<Reminder> reminders;
  final VoidCallback onAdd;
  final ValueChanged<Reminder> onOpenReminder;
  final AlarmReadiness? readiness;

  @override
  Widget build(BuildContext context) {
    final next = reminders.isEmpty ? null : reminders.first;
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
                Text(_friendlyDate(DateTime.now()), style: _subtle(context)),
              ],
            ),
            ReadinessChip(readiness: readiness),
          ],
        ),
        const SizedBox(height: 30),
        Text('NEXT UP', style: _sectionLabel(context)),
        const SizedBox(height: 10),
        if (next == null)
          EmptyReminderCard(onAdd: onAdd)
        else
          NextReminderCard(reminder: next, onOpen: () => onOpenReminder(next)),
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Later today', style: Theme.of(context).textTheme.titleLarge),
            TextButton(onPressed: onAdd, child: const Text('Add')),
          ],
        ),
        const SizedBox(height: 4),
        ...reminders.skip(next == null ? 0 : 1).map(
              (reminder) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ReminderRow(reminder: reminder, onTap: () => onOpenReminder(reminder)),
              ),
            ),
        const SizedBox(height: 18),
        if (_readinessWarnings(readiness).isNotEmpty) ...[
          PermissionWarningCard(messages: _readinessWarnings(readiness)),
          const SizedBox(height: 12),
        ],
        const ReliabilityNote(),
      ],
    );
  }
}

class PermissionWarningCard extends StatelessWidget {
  const PermissionWarningCard({super.key, required this.messages});

  final List<String> messages;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.amberLight, borderRadius: BorderRadius.circular(18)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.amber),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Reliable Alarm needs attention', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink)),
                const SizedBox(height: 6),
                ...messages.map(
                  (message) => Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text('• $message', style: const TextStyle(height: 1.3)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyReminderCard extends StatelessWidget {
  const EmptyReminderCard({super.key, required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.notifications_none_rounded, color: AppColors.sage),
          const SizedBox(height: 12),
          Text('No reminders yet', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('Create a gentle reminder, alarm reminder, or speaking alarm.', style: _subtle(context)),
          const SizedBox(height: 14),
          FilledButton.icon(onPressed: onAdd, icon: const Icon(Icons.add_rounded), label: const Text('Add reminder')),
        ],
      ),
    );
  }
}

class ReadinessChip extends StatelessWidget {
  const ReadinessChip({super.key, required this.readiness});

  final AlarmReadiness? readiness;

  @override
  Widget build(BuildContext context) {
    final ready = readiness?.isReady ?? false;
    final unknown = readiness == null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: ready ? AppColors.sageLight : AppColors.amberLight,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ready ? Icons.check_circle_rounded : Icons.info_outline_rounded, size: 16, color: ready ? AppColors.sage : AppColors.amber),
          const SizedBox(width: 5),
          Text(
            unknown ? 'Checking' : ready ? 'Ready' : 'Needs setup',
            style: TextStyle(color: ready ? AppColors.sage : AppColors.amber, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class NextReminderCard extends StatelessWidget {
  const NextReminderCard({super.key, required this.reminder, required this.onOpen});

  final Reminder reminder;
  final VoidCallback onOpen;

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
              IconButton(onPressed: onOpen, icon: const Icon(Icons.more_horiz_rounded)),
            ],
          ),
          const SizedBox(height: 22),
          Text(reminder.time, style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(reminder.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(reminder.detail, style: _subtle(context)),
          if (!reminder.enabled) ...[
            const SizedBox(height: 8),
            const Text('Paused', style: TextStyle(color: AppColors.amber, fontWeight: FontWeight.w800)),
          ],
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
  const ReminderRow({super.key, required this.reminder, this.onTap});

  final Reminder reminder;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
        children: [
          ReminderIcon(type: reminder.type),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: reminder.enabled ? null : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 3),
                Text(reminder.detail, style: _subtle(context, small: true)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(reminder.time, style: const TextStyle(fontWeight: FontWeight.w800)),
              if (!reminder.enabled)
                const Padding(padding: EdgeInsets.only(top: 4), child: Icon(Icons.pause_circle_outline_rounded, size: 16, color: AppColors.amber))
              else if (reminder.isAlarm)
                const Padding(padding: EdgeInsets.only(top: 4), child: Icon(Icons.volume_up_rounded, size: 15, color: AppColors.amber)),
            ],
          ),
        ],
          ),
        ),
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
  const RoutinesScreen({
    super.key,
    required this.reminders,
    required this.onAdd,
    required this.onAddForType,
    required this.onOpenReminder,
  });

  final List<Reminder> reminders;
  final VoidCallback onAdd;
  final ValueChanged<ReminderType> onAddForType;
  final ValueChanged<Reminder> onOpenReminder;

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
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            RoutinePreset(icon: Icons.water_drop_outlined, label: 'Drink water', onTap: () => onAddForType(ReminderType.water)),
            RoutinePreset(icon: Icons.visibility_outlined, label: 'Eye break', onTap: () => onAddForType(ReminderType.breakTime)),
            RoutinePreset(icon: Icons.self_improvement_outlined, label: 'Stretch', onTap: () => onAddForType(ReminderType.breakTime)),
            RoutinePreset(icon: Icons.directions_walk_outlined, label: 'Walk', onTap: () => onAddForType(ReminderType.breakTime)),
          ],
        ),
        const SizedBox(height: 30),
        Text('YOUR ROUTINES', style: _sectionLabel(context)),
        const SizedBox(height: 10),
        ...reminders.where((item) => item.type != ReminderType.meeting).map((item) => Padding(padding: const EdgeInsets.only(bottom: 10), child: ReminderRow(reminder: item, onTap: () => onOpenReminder(item)))),
        const SizedBox(height: 10),
        OutlinedButton.icon(onPressed: onAdd, icon: const Icon(Icons.add_rounded), label: const Text('Create a custom routine')),
      ],
    );
  }
}

class RoutinePreset extends StatelessWidget {
  const RoutinePreset({super.key, required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 152,
          padding: const EdgeInsets.all(15),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: AppColors.sage), const SizedBox(height: 16), Text(label, style: const TextStyle(fontWeight: FontWeight.w800))]),
        ),
      ),
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
                  detail: 'Allow Reliable alarms to interrupt Do Not Disturb',
                  ready: _readiness?.dndPolicyAccess ?? false,
                  action: () => _perform(ReliabilityPlatform.openDndSettings),
                  actionLabel: 'Open channel',
                ),
                _ReadinessItem(
                  title: 'Full-screen alarms',
                  detail: 'Let alarms take over the lock screen',
                  ready: _readiness?.fullScreenIntentEnabled ?? false,
                  action: () => _perform(ReliabilityPlatform.openFullScreenIntentSettings),
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

class ReminderDetailScreen extends StatelessWidget {
  const ReminderDetailScreen({
    super.key,
    required this.reminder,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleEnabled,
  });

  final Reminder reminder;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggleEnabled;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminder details'),
        actions: [
          IconButton(tooltip: 'Edit reminder', onPressed: onEdit, icon: const Icon(Icons.edit_outlined)),
          IconButton(
            tooltip: 'Delete reminder',
            onPressed: () => _confirmDelete(context),
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(child: ReminderIcon(type: reminder.type, large: true)),
          const SizedBox(height: 20),
          Text(reminder.title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(reminder.time, textAlign: TextAlign.center, style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 28),
          _DetailCard(label: 'Schedule', value: reminder.detail),
          const SizedBox(height: 10),
          _DetailCard(label: 'Delivery', value: _deliveryLabel(reminder.deliveryMode)),
          const SizedBox(height: 10),
          _DetailCard(label: 'Tone', value: _toneLabel(reminder.tone)),
          if (reminder.isSpeakingAlarm) ...[
            const SizedBox(height: 10),
            _DetailCard(label: 'Spoken message', value: reminder.spokenMessage.isEmpty ? 'It is time for ${reminder.title}' : reminder.spokenMessage),
          ],
          const SizedBox(height: 10),
          Material(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            child: SwitchListTile.adaptive(
              value: reminder.enabled,
              onChanged: onToggleEnabled,
              secondary: Icon(reminder.enabled ? Icons.play_circle_outline_rounded : Icons.pause_circle_outline_rounded),
              title: const Text('Enabled', style: TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(reminder.enabled ? 'This reminder can fire' : 'Paused reminders stay saved but do not fire'),
            ),
          ),
          const SizedBox(height: 28),
          if (reminder.type == ReminderType.meeting)
            FilledButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Meeting links will be connected with Google Calendar setup.'))),
              icon: const Icon(Icons.videocam_rounded),
              label: const Text('Join meeting'),
            )
          else
            FilledButton.tonalIcon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Snoozed for 10 minutes.'))),
              icon: const Icon(Icons.snooze_rounded),
              label: const Text('Snooze 10 min'),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final delete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete reminder?'),
        content: Text('${reminder.title} will be removed from Speaking Clock.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton.tonal(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (delete == true) onDelete();
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: _sectionLabel(context)), const SizedBox(height: 6), Text(value, style: Theme.of(context).textTheme.bodyLarge)]),
    );
  }
}

class _SchedulePreview extends StatelessWidget {
  const _SchedulePreview({required this.triggerAt, this.customRepeatMinutes});

  final DateTime triggerAt;
  final int? customRepeatMinutes;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final triggerDay = DateTime(triggerAt.year, triggerAt.month, triggerAt.day);
    final dayLabel = triggerDay == today ? 'Today' : 'Tomorrow';
    final isTomorrow = dayLabel == 'Tomorrow';
    final text = customRepeatMinutes == null
        ? 'Will fire $dayLabel at ${_formatTime12(TimeOfDay.fromDateTime(triggerAt))}'
        : 'First fire $dayLabel at ${_formatTime12(TimeOfDay.fromDateTime(triggerAt))}, then every $customRepeatMinutes min';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isTomorrow ? AppColors.amberLight : AppColors.sageLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(isTomorrow ? Icons.info_outline_rounded : Icons.check_circle_outline_rounded, size: 18, color: isTomorrow ? AppColors.amber : AppColors.sage),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: isTomorrow ? AppColors.amber : AppColors.sage, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class ReminderEditor extends StatefulWidget {
  const ReminderEditor({super.key, required this.initialType, this.reminder});

  final ReminderType initialType;
  final Reminder? reminder;

  @override
  State<ReminderEditor> createState() => _ReminderEditorState();
}

class _ReminderEditorState extends State<ReminderEditor> {
  final _controller = TextEditingController();
  final _spokenController = TextEditingController();
  final _customRepeatController = TextEditingController(text: '30');
  static const _repeatOptions = ['Once', 'Every day', 'Weekdays', 'Custom minutes'];
  late ReminderType _type;
  late DeliveryMode _deliveryMode;
  late ToneOption _tone;
  late TimeOfDay _time;
  var _frequency = 'Every day';
  var _snoozeMinutes = 10;

  String get _selectedRepeatRule {
    if (_frequency != 'Custom minutes') return _frequency;
    return 'Every $_customRepeatMinutes min';
  }

  int get _customRepeatMinutes {
    final minutes = int.tryParse(_customRepeatController.text.trim());
    return minutes == null ? 30 : minutes.clamp(1, 1440);
  }

  DateTime get _selectedTriggerAt {
    return _triggerForTime(_time);
  }

  @override
  void initState() {
    super.initState();
    final reminder = widget.reminder;
    _type = reminder?.type ?? widget.initialType;
    _deliveryMode = reminder?.deliveryMode ?? DeliveryMode.gentle;
    _tone = reminder?.tone ?? ToneOption.softChime;
    _time = _defaultReminderTime();
    _snoozeMinutes = reminder?.snoozeMinutes ?? 10;
    if (reminder != null) {
      _controller.text = reminder.title;
      _spokenController.text = reminder.spokenMessage;
      final savedRepeat = reminder.detail.split(' · ').first;
      final customMinutes = _customRepeatMinutesFromRule(savedRepeat);
      if (customMinutes != null) {
        _frequency = 'Custom minutes';
        _customRepeatController.text = '$customMinutes';
      } else {
        _frequency = _repeatOptions.contains(savedRepeat) ? savedRepeat : 'Every day';
      }
      _time = _parseTimeLabel(reminder.time) ?? _time;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _spokenController.dispose();
    _customRepeatController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      builder: (context, child) {
        return MediaQuery(data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false), child: child ?? const SizedBox.shrink());
      },
    );
    if (picked != null) setState(() => _time = picked);
  }

  void _save() {
    final title = _controller.text.trim().isEmpty ? 'Drink water' : _controller.text.trim();
    final now = DateTime.now();
    final triggerAt = _selectedTriggerAt;
    final reminder = widget.reminder;
    final spokenMessage = _spokenController.text.trim();
    final repeatRule = _selectedRepeatRule;
    Navigator.pop(
      context,
      Reminder(
        id: reminder?.id ?? '${now.microsecondsSinceEpoch}',
        title: title,
        time: _formatTime12(_time),
        detail: '$repeatRule · ${_deliveryLabel(_deliveryMode)}',
        type: _type,
        deliveryMode: _deliveryMode,
        spokenMessage: spokenMessage,
        tone: _tone,
        enabled: reminder?.enabled ?? true,
        snoozeMinutes: _snoozeMinutes,
        triggerAtMillis: triggerAt.millisecondsSinceEpoch,
        createdAtMillis: reminder?.createdAtMillis ?? now.millisecondsSinceEpoch,
        updatedAtMillis: now.millisecondsSinceEpoch,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(widget.reminder == null ? 'New reminder' : 'Edit reminder', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              TextField(controller: _controller, autofocus: true, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'What should we remind you?', hintText: 'Drink water', border: OutlineInputBorder())),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ReminderType.values.map((type) => ChoiceChip(label: Text(_label(type)), selected: type == _type, onSelected: (_) => setState(() => _type = type))).toList(),
              ),
              const SizedBox(height: 18),
              Text('Delivery', style: _sectionLabel(context)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: DeliveryMode.values
                    .map((mode) => ChoiceChip(
                          label: Text(_deliveryLabel(mode)),
                          selected: mode == _deliveryMode,
                          onSelected: (_) => setState(() => _deliveryMode = mode),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 18),
              Row(children: [
                Expanded(child: OutlinedButton.icon(onPressed: _pickTime, icon: const Icon(Icons.schedule_outlined), label: Text(_formatTime12(_time)))),
                const SizedBox(width: 10),
                Expanded(child: DropdownButtonFormField<String>(initialValue: _frequency, decoration: const InputDecoration(labelText: 'Repeat', border: OutlineInputBorder()), items: _repeatOptions.map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(), onChanged: (value) => setState(() => _frequency = value ?? _frequency))),
              ]),
              if (_frequency == 'Custom minutes') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _customRepeatController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Repeat every',
                    suffixText: 'minutes',
                    helperText: 'Example: 25 means this reminder repeats every 25 minutes.',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],
              const SizedBox(height: 8),
              _SchedulePreview(triggerAt: _selectedTriggerAt, customRepeatMinutes: _frequency == 'Custom minutes' ? _customRepeatMinutes : null),
              const SizedBox(height: 12),
              DropdownButtonFormField<ToneOption>(
                initialValue: _tone,
                decoration: const InputDecoration(labelText: 'Tone', border: OutlineInputBorder()),
                items: ToneOption.values.map((tone) => DropdownMenuItem(value: tone, child: Text(_toneLabel(tone)))).toList(),
                onChanged: (value) => setState(() => _tone = value ?? _tone),
              ),
              if (_deliveryMode == DeliveryMode.speaking) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _spokenController,
                  minLines: 2,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: 'What should it speak?',
                    hintText: 'It is time for ${_controller.text.trim().isEmpty ? 'this reminder' : _controller.text.trim()}',
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _snoozeMinutes,
                decoration: const InputDecoration(labelText: 'Snooze', border: OutlineInputBorder()),
                items: const [5, 10, 15, 30].map((value) => DropdownMenuItem(value: value, child: Text('$value minutes'))).toList(),
                onChanged: (value) => setState(() => _snoozeMinutes = value ?? _snoozeMinutes),
              ),
              const SizedBox(height: 18),
              SizedBox(width: double.infinity, child: FilledButton(onPressed: _save, child: Text(widget.reminder == null ? 'Save reminder' : 'Save changes'))),
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

String _deliveryLabel(DeliveryMode mode) => switch (mode) {
      DeliveryMode.gentle => 'Gentle Reminder',
      DeliveryMode.alarm => 'Alarm Reminder',
      DeliveryMode.speaking => 'Speaking Alarm',
    };

String _toneLabel(ToneOption tone) => switch (tone) {
      ToneOption.softChime => 'Soft Chime',
      ToneOption.classicAlarm => 'Classic Alarm',
      ToneOption.digitalBeep => 'Digital Beep',
      ToneOption.morningBell => 'Morning Bell',
      ToneOption.calmWater => 'Calm Water',
      ToneOption.vibrationOnly => 'Vibration Only',
    };

T _enumValue<T>(List<T> values, int index, T fallback) {
  if (index < 0 || index >= values.length) return fallback;
  return values[index];
}

DeliveryMode _deliveryModeFromName(String name) {
  return DeliveryMode.values.firstWhere(
    (mode) => mode.name == name,
    orElse: () => DeliveryMode.gentle,
  );
}

ToneOption _toneFromName(String name) {
  return ToneOption.values.firstWhere(
    (tone) => tone.name == name,
    orElse: () => ToneOption.softChime,
  );
}

List<Reminder> _sortReminders(List<Reminder> reminders) {
  final sorted = [...reminders];
  sorted.sort((a, b) {
    if (a.enabled != b.enabled) return a.enabled ? -1 : 1;
    final aTime = a.triggerAtMillis ?? 1 << 62;
    final bTime = b.triggerAtMillis ?? 1 << 62;
    return aTime.compareTo(bTime);
  });
  return sorted;
}

String _repeatRule(Reminder reminder) {
  return reminder.detail.split(' · ').first;
}

String _friendlyDate(DateTime date) {
  const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
  return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
}

List<String> _readinessWarnings(AlarmReadiness? readiness) {
  if (readiness == null) return const [];
  final warnings = <String>[];
  if (!readiness.notificationsEnabled) warnings.add('Notifications are off, so reminders may not appear.');
  if (!readiness.exactAlarmEnabled) warnings.add('Exact alarms are off, so important alarms may not fire on time.');
  if (!readiness.fullScreenIntentEnabled) warnings.add('Full-screen alarms are off, so lock-screen alarm screens may not appear.');
  if (!readiness.alarmVolumeEnabled) warnings.add('Alarm volume is muted, so alarm sound may not be audible.');
  if (!readiness.dndPolicyAccess) warnings.add('Reliable alarms cannot interrupt DND. Android alarms may still fire, but allow this for the safest DND behavior.');
  return warnings;
}

TimeOfDay _defaultReminderTime() {
  final now = DateTime.now().add(const Duration(minutes: 5));
  return TimeOfDay(hour: now.hour, minute: now.minute);
}

DateTime _triggerForTime(TimeOfDay time) {
  final now = DateTime.now();
  var triggerAt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
  if (!triggerAt.isAfter(now)) triggerAt = triggerAt.add(const Duration(days: 1));
  return triggerAt;
}

String _formatTime12(TimeOfDay time) {
  final period = time.hour >= 12 ? 'PM' : 'AM';
  final hour12 = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour12:$minute $period';
}

int? _customRepeatMinutesFromRule(String rule) {
  final match = RegExp(r'^Every\s+(\d+)\s+min$', caseSensitive: false).firstMatch(rule.trim());
  if (match == null) return null;
  final minutes = int.tryParse(match.group(1) ?? '');
  if (minutes == null || minutes <= 0) return null;
  return minutes;
}

TimeOfDay? _parseTimeLabel(String value) {
  final normalized = value.trim().toUpperCase();
  final match = RegExp(r'^(\d{1,2}):(\d{2})(?:\s*(AM|PM))?$').firstMatch(normalized);
  if (match == null) return null;
  var hour = int.tryParse(match.group(1) ?? '');
  final minute = int.tryParse(match.group(2) ?? '');
  if (hour == null || minute == null || minute > 59) return null;
  final period = match.group(3);
  if (period == 'PM' && hour < 12) hour += 12;
  if (period == 'AM' && hour == 12) hour = 0;
  if (hour > 23) return null;
  return TimeOfDay(hour: hour, minute: minute);
}
