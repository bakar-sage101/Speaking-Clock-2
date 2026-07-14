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

enum ToneOption {
  softChime,
  classicAlarm,
  digitalBeep,
  morningBell,
  calmWater,
  vibrationOnly,
}

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
  }) => Reminder(
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

class ReminderDraft {
  const ReminderDraft({
    required this.title,
    required this.type,
    required this.deliveryMode,
    required this.repeatRule,
    required this.tone,
    this.spokenMessage = '',
    this.snoozeMinutes = 10,
  });

  final String title;
  final ReminderType type;
  final DeliveryMode deliveryMode;
  final String repeatRule;
  final ToneOption tone;
  final String spokenMessage;
  final int snoozeMinutes;
}

class SpeakingClockApp extends StatefulWidget {
  const SpeakingClockApp({super.key});

  @override
  State<SpeakingClockApp> createState() => _SpeakingClockAppState();
}

class _SpeakingClockAppState extends State<SpeakingClockApp>
    with WidgetsBindingObserver {
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
      await Future.wait(
        _reminders.map(
          (reminder) => _database.saveReminder(reminder.toCompanion()),
        ),
      );
      return;
    }
    setState(
      () =>
          _reminders = _sortReminders(saved.map(Reminder.fromRecord).toList()),
    );
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

  Future<void> _showAddReminder({
    ReminderType initialType = ReminderType.water,
    ReminderDraft? draft,
  }) async {
    final reminder = await showModalBottomSheet<Reminder>(
      context: _navigatorKey.currentState!.context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReminderEditor(initialType: initialType, draft: draft),
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
      builder: (_) =>
          ReminderEditor(initialType: original.type, reminder: original),
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
    setState(
      () => _reminders = _sortReminders(
        _reminders.where((item) => item.id != reminder.id).toList(),
      ),
    );
    await _database.deleteReminderById(reminder.id);
    _navigatorKey.currentState?.pop();
    _messengerKey.currentState?.showSnackBar(
      SnackBar(content: Text('${reminder.title} deleted.')),
    );
  }

  Future<void> _toggleReminder(Reminder reminder, bool enabled) async {
    if (!enabled) await _cancelDeviceReminder(reminder);
    final updated = reminder.copyWith(
      enabled: enabled,
      updatedAtMillis: DateTime.now().millisecondsSinceEpoch,
    );
    setState(() {
      _reminders = _sortReminders([
        for (final item in _reminders)
          if (item.id == reminder.id) updated else item,
      ]);
    });
    await _database.setReminderEnabled(reminder.id, enabled);
    if (enabled) await _scheduleDeviceReminder(updated);
    _messengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text('${reminder.title} ${enabled ? 'resumed' : 'paused'}.'),
      ),
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
      final canSchedule = switch (reminder.deliveryMode) {
        DeliveryMode.gentle => readiness.canScheduleGentleReminders,
        DeliveryMode.alarm ||
        DeliveryMode.speaking => readiness.canScheduleReliableAlarms,
      };
      if (!canSchedule) {
        await _cancelDeviceReminder(reminder);
        if (mounted) {
          _messengerKey.currentState?.showSnackBar(
            SnackBar(
              content: Text(_scheduleBlockedMessage(reminder, readiness)),
            ),
          );
        }
        return;
      }
      await ReliabilityPlatform.scheduleAlarm(
        id: reminder.id.hashCode & 0x7fffffff,
        triggerAt: DateTime.fromMillisecondsSinceEpoch(
          reminder.triggerAtMillis!,
        ),
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
            ? ' Allow Reliable alarms to interrupt DND for the safest behavior.'
            : '';
        _messengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(
              '${_deliveryLabel(reminder.deliveryMode)} scheduled.$dndNote',
            ),
          ),
        );
      }
    } on PlatformException catch (error) {
      if (mounted) {
        _messengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(
              error.message ?? 'Reliable Alarm could not be scheduled.',
            ),
          ),
        );
      }
    } on MissingPluginException {
      if (mounted) {
        _messengerKey.currentState?.showSnackBar(
          const SnackBar(
            content: Text(
              'Reliable Alarm is not available on this platform yet.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _cancelDeviceReminder(Reminder reminder) async {
    try {
      await ReliabilityPlatform.cancelAlarm(
        id: reminder.id.hashCode & 0x7fffffff,
      );
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
        scaffoldBackgroundColor: _darkMode
            ? const Color(0xff111411)
            : AppColors.canvas,
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
                      onOpenReliability: () => _navigatorKey.currentState!
                          .push(
                            MaterialPageRoute<void>(
                              builder: (_) => const ReliabilityScreen(),
                            ),
                          )
                          .then((_) => _refreshReadiness()),
                      readiness: _readiness,
                    ),
                    RoutinesScreen(
                      reminders: _reminders,
                      onAdd: _showAddReminder,
                      onUseTemplate: (draft) => _showAddReminder(
                        initialType: draft.type,
                        draft: draft,
                      ),
                      onOpenReminder: _openReminderDetails,
                    ),
                    SettingsScreen(
                      darkMode: _darkMode,
                      readiness: _readiness,
                      onDarkModeChanged: (value) =>
                          setState(() => _darkMode = value),
                      onOpenReliability: () => _navigatorKey.currentState!
                          .push(
                            MaterialPageRoute<void>(
                              builder: (_) => const ReliabilityScreen(),
                            ),
                          )
                          .then((_) => _refreshReadiness()),
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

class _OnboardingScreenState extends State<OnboardingScreen>
    with WidgetsBindingObserver {
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
    _controller.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  List<_OnboardingPage> get _pages => [
    _OnboardingPage(
      icon: Icons.waving_hand_outlined,
      title: 'Welcome to Speaking Clock',
      body:
          'A calm reminder app for the moments when focus pulls you too deep.',
      primaryLabel: 'Set up my reminders',
      onPrimary: _next,
    ),
    _OnboardingPage(
      icon: Icons.tune_rounded,
      title: 'Choose how strongly it should interrupt',
      body:
          'Gentle is a light nudge. Alarm keeps ringing until acknowledged. Speaking says your custom message first, then rings.',
      primaryLabel: 'Continue',
      onPrimary: _next,
    ),
    _OnboardingPage(
      icon: Icons.notifications_active_outlined,
      title: 'Allow notifications',
      body:
          'Reminders need notifications so they can appear while the app is closed or you are using something else.',
      ready: _readiness?.notificationsEnabled,
      primaryLabel: _readiness?.notificationsEnabled == true
          ? 'Notifications ready'
          : 'Allow notifications',
      onPrimary: _readiness?.notificationsEnabled == true
          ? _next
          : () => _run(ReliabilityPlatform.requestNotifications),
    ),
    _OnboardingPage(
      icon: Icons.alarm_on_rounded,
      title: 'Allow exact alarms',
      body:
          'Important reminders need exact alarm access so Android lets them fire at the time you chose.',
      ready: _readiness?.exactAlarmEnabled,
      primaryLabel: _readiness?.exactAlarmEnabled == true
          ? 'Exact alarms ready'
          : 'Allow exact alarms',
      onPrimary: _readiness?.exactAlarmEnabled == true
          ? _next
          : () => _run(ReliabilityPlatform.requestExactAlarms),
    ),
    _OnboardingPage(
      icon: Icons.phone_android_rounded,
      title: 'Allow full-screen alarms',
      body:
          'This lets Alarm Reminder and Speaking Alarm show the calm lock-screen screen with Acknowledge and Snooze.',
      ready: _readiness?.fullScreenIntentEnabled,
      primaryLabel: _readiness?.fullScreenIntentEnabled == true
          ? 'Full-screen ready'
          : 'Open full-screen setting',
      onPrimary: _readiness?.fullScreenIntentEnabled == true
          ? _next
          : () => _run(ReliabilityPlatform.openFullScreenIntentSettings),
    ),
    _OnboardingPage(
      icon: Icons.do_not_disturb_on_outlined,
      title: 'Do Not Disturb behavior',
      body:
          'Recommended: allow reliable alarms to interrupt Do Not Disturb. Android alarms may still fire, but this keeps behavior clearer.',
      ready: _readiness?.dndPolicyAccess,
      primaryLabel: _readiness?.dndPolicyAccess == true
          ? 'DND ready'
          : 'Open DND setting',
      onPrimary: _readiness?.dndPolicyAccess == true
          ? _next
          : () => _run(ReliabilityPlatform.openDndSettings),
      secondaryLabel: 'I will do this later',
      onSecondary: _next,
    ),
    _OnboardingPage(
      icon: Icons.volume_up_outlined,
      title: 'Check alarm volume',
      body:
          'Keep alarm volume above the lowest level. Speaking alarms and alarm reminders need Android’s alarm volume to be safely audible.',
      ready: _readiness?.alarmVolumeEnabled,
      primaryLabel: _readiness?.alarmVolumeEnabled == true
          ? 'Volume ready'
          : 'Check again',
      onPrimary: _readiness?.alarmVolumeEnabled == true
          ? _next
          : () => _run(_refresh),
      secondaryLabel: 'Continue anyway',
      onSecondary: _next,
    ),
    _OnboardingPage(
      icon: Icons.verified_rounded,
      title: 'You are ready',
      body:
          'Create a short test reminder whenever you want to verify the flow again.',
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
                  Text(
                    '${_page + 1}/${pages.length}',
                    style: _sectionLabel(context),
                  ),
                ],
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  onPageChanged: (value) => setState(() => _page = value),
                  itemCount: pages.length,
                  itemBuilder: (context, index) => _OnboardingPageView(
                    page: pages[index],
                    loading: _loading,
                  ),
                ),
              ),
              Row(
                children: [
                  if (_page > 0)
                    TextButton(
                      onPressed: () => _controller.previousPage(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                      ),
                      child: const Text('Back'),
                    )
                  else
                    const SizedBox(width: 72),
                  const Spacer(),
                  TextButton(
                    onPressed: widget.onComplete,
                    child: const Text('Skip'),
                  ),
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
              child: Icon(
                ready ? Icons.check_rounded : page.icon,
                size: 42,
                color: ready ? AppColors.sage : AppColors.amber,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              page.title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            Text(
              page.body,
              textAlign: TextAlign.center,
              style: _subtle(context),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: loading ? null : page.onPrimary,
                child: loading
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(page.primaryLabel),
              ),
            ),
            if (page.secondaryLabel != null && page.onSecondary != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: loading ? null : page.onSecondary,
                child: Text(page.secondaryLabel!),
              ),
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
    required this.onOpenReliability,
    required this.readiness,
  });

  final List<Reminder> reminders;
  final VoidCallback onAdd;
  final ValueChanged<Reminder> onOpenReminder;
  final VoidCallback onOpenReliability;
  final AlarmReadiness? readiness;

  @override
  Widget build(BuildContext context) {
    final next = reminders.isEmpty ? null : reminders.first;
    final warnings = _readinessWarnings(readiness);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 108),
      children: [
        _TodayHeader(readiness: readiness),
        if (warnings.isNotEmpty) ...[
          const SizedBox(height: 18),
          PermissionWarningCard(
            messages: warnings,
            onReview: onOpenReliability,
          ),
        ],
        const SizedBox(height: 28),
        Row(
          children: [
            Text('Next up', style: _sectionLabel(context)),
            const SizedBox(width: 8),
            if (next != null)
              _TinyBadge(
                label: next.enabled ? 'Active' : 'Paused',
                color: next.enabled ? AppColors.sage : AppColors.amber,
              ),
          ],
        ),
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
        ...reminders
            .skip(next == null ? 0 : 1)
            .map(
              (reminder) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ReminderRow(
                  reminder: reminder,
                  onTap: () => onOpenReminder(reminder),
                ),
              ),
            ),
        const SizedBox(height: 18),
        const ReliabilityNote(),
      ],
    );
  }
}

class _TodayHeader extends StatelessWidget {
  const _TodayHeader({required this.readiness});

  final AlarmReadiness? readiness;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: AppColors.sageLight,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.wb_sunny_outlined, color: AppColors.sage),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting(),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(_friendlyDate(DateTime.now()), style: _subtle(context)),
              ],
            ),
          ),
          ReadinessChip(readiness: readiness),
        ],
      ),
    );
  }
}

class PermissionWarningCard extends StatelessWidget {
  const PermissionWarningCard({
    super.key,
    required this.messages,
    required this.onReview,
  });

  final List<String> messages;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.amberLight,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.amber),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Reliable Alarm needs attention',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                ...messages.map(
                  (message) => Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      '• $message',
                      style: const TextStyle(height: 1.3),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed: onReview,
                  icon: const Icon(Icons.shield_outlined),
                  label: const Text('Review setup'),
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 58,
            width: 58,
            decoration: BoxDecoration(
              color: AppColors.sageLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: AppColors.sage,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Your day is quiet',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            'Create a gentle nudge, a full-screen alarm, or a spoken reminder when something matters.',
            style: _subtle(context),
          ),
          const SizedBox(height: 14),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TinyBadge(
                label: 'Drink water',
                color: AppColors.blue,
                icon: Icons.water_drop_outlined,
              ),
              _TinyBadge(
                label: 'Stretch',
                color: AppColors.sage,
                icon: Icons.self_improvement_outlined,
              ),
              _TinyBadge(
                label: 'Meeting prep',
                color: AppColors.amber,
                icon: Icons.videocam_outlined,
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create your first reminder'),
          ),
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
          Icon(
            ready ? Icons.check_circle_rounded : Icons.info_outline_rounded,
            size: 16,
            color: ready ? AppColors.sage : AppColors.amber,
          ),
          const SizedBox(width: 5),
          Text(
            unknown
                ? 'Checking'
                : ready
                ? 'Ready'
                : 'Needs setup',
            style: TextStyle(
              color: ready ? AppColors.sage : AppColors.amber,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _TinyBadge extends StatelessWidget {
  const _TinyBadge({required this.label, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class NextReminderCard extends StatelessWidget {
  const NextReminderCard({
    super.key,
    required this.reminder,
    required this.onOpen,
  });

  final Reminder reminder;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final accent = _deliveryAccent(reminder.deliveryMode);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ReminderIcon(type: reminder.type, large: true),
              _TinyBadge(
                label: _deliveryShortLabel(reminder.deliveryMode),
                color: accent,
                icon: _deliveryIcon(reminder.deliveryMode),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            reminder.time,
            style: Theme.of(
              context,
            ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(
            reminder.title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TinyBadge(
                label: _repeatRule(reminder),
                color: AppColors.sage,
                icon: Icons.repeat_rounded,
              ),
              _TinyBadge(
                label: _toneLabel(reminder.tone),
                color: AppColors.amber,
                icon: _toneIcon(reminder.tone),
              ),
              if (reminder.isSpeakingAlarm)
                const _TinyBadge(
                  label: 'Speaks',
                  color: AppColors.amber,
                  icon: Icons.record_voice_over_rounded,
                ),
            ],
          ),
          if (!reminder.enabled) ...[
            const SizedBox(height: 12),
            const _TinyBadge(
              label: 'Paused',
              color: AppColors.amber,
              icon: Icons.pause_circle_outline_rounded,
            ),
          ],
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: onOpen,
            icon: const Icon(Icons.tune_rounded),
            label: const Text('Open reminder'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(46),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
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
    final accent = _deliveryAccent(reminder.deliveryMode);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: reminder.enabled
                ? Theme.of(context).colorScheme.surface
                : Theme.of(context).colorScheme.surface.withValues(alpha: 0.58),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.line),
          ),
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
                        fontWeight: FontWeight.w900,
                        color: reminder.enabled
                            ? null
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _TinyBadge(
                          label: _deliveryShortLabel(reminder.deliveryMode),
                          color: accent,
                          icon: _deliveryIcon(reminder.deliveryMode),
                        ),
                        _TinyBadge(
                          label: _repeatRule(reminder),
                          color: AppColors.sage,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    reminder.time,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  if (!reminder.enabled)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Icon(
                        Icons.pause_circle_outline_rounded,
                        size: 16,
                        color: AppColors.amber,
                      ),
                    )
                  else if (reminder.isAlarm)
                    Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Icon(
                        reminder.isSpeakingAlarm
                            ? Icons.record_voice_over_rounded
                            : Icons.alarm_rounded,
                        size: 15,
                        color: accent,
                      ),
                    ),
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
      ReminderType.breakTime => (
        Icons.self_improvement_outlined,
        AppColors.sage,
      ),
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
      decoration: BoxDecoration(
        color: AppColors.sageLight,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_user_outlined, color: AppColors.sage),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Set up Reliable Alarm before using it for important reminders. We will check the required device permissions for you.',
              style: TextStyle(height: 1.35),
            ),
          ),
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
    required this.onUseTemplate,
    required this.onOpenReminder,
  });

  final List<Reminder> reminders;
  final VoidCallback onAdd;
  final ValueChanged<ReminderDraft> onUseTemplate;
  final ValueChanged<Reminder> onOpenReminder;

  @override
  Widget build(BuildContext context) {
    final routines = reminders
        .where((item) => item.type != ReminderType.meeting)
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 108),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  color: AppColors.sageLight,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.sage,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Routines',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Quick-start reminders for a healthier workday.',
                      style: _subtle(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Text('Quick start', style: _sectionLabel(context)),
        const SizedBox(height: 10),
        ..._routineTemplates.map(
          (template) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: RoutinePreset(
              template: template,
              onTap: () => onUseTemplate(template.draft),
            ),
          ),
        ),
        const SizedBox(height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Your routines', style: _sectionLabel(context)),
            _TinyBadge(label: '${routines.length}', color: AppColors.sage),
          ],
        ),
        const SizedBox(height: 10),
        if (routines.isEmpty)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.line),
            ),
            child: Text(
              'No routines yet. Pick a quick-start template above or create your own.',
              style: _subtle(context),
            ),
          )
        else
          ...routines.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ReminderRow(
                reminder: item,
                onTap: () => onOpenReminder(item),
              ),
            ),
          ),
        const SizedBox(height: 10),
        FilledButton.tonalIcon(
          onPressed: onAdd,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Create a custom routine'),
        ),
      ],
    );
  }
}

class RoutineTemplate {
  const RoutineTemplate({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.draft,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final ReminderDraft draft;
}

const _routineTemplates = [
  RoutineTemplate(
    icon: Icons.water_drop_outlined,
    title: 'Drink water',
    subtitle: 'A gentle hydration nudge during work.',
    color: AppColors.blue,
    draft: ReminderDraft(
      title: 'Drink water',
      type: ReminderType.water,
      deliveryMode: DeliveryMode.gentle,
      repeatRule: 'Every 60 min',
      tone: ToneOption.calmWater,
      snoozeMinutes: 10,
    ),
  ),
  RoutineTemplate(
    icon: Icons.self_improvement_outlined,
    title: 'Stand and stretch',
    subtitle: 'Step away from the desk for a quick reset.',
    color: AppColors.sage,
    draft: ReminderDraft(
      title: 'Stand and stretch',
      type: ReminderType.breakTime,
      deliveryMode: DeliveryMode.gentle,
      repeatRule: 'Every 90 min',
      tone: ToneOption.softChime,
      snoozeMinutes: 10,
    ),
  ),
  RoutineTemplate(
    icon: Icons.visibility_outlined,
    title: 'Eye break',
    subtitle: 'Look away from the screen and relax your eyes.',
    color: AppColors.blue,
    draft: ReminderDraft(
      title: 'Eye break',
      type: ReminderType.breakTime,
      deliveryMode: DeliveryMode.gentle,
      repeatRule: 'Every 30 min',
      tone: ToneOption.softChime,
      snoozeMinutes: 5,
    ),
  ),
  RoutineTemplate(
    icon: Icons.medication_outlined,
    title: 'Medication',
    subtitle: 'A stronger reminder for something important.',
    color: AppColors.amber,
    draft: ReminderDraft(
      title: 'Take medication',
      type: ReminderType.medication,
      deliveryMode: DeliveryMode.alarm,
      repeatRule: 'Every day',
      tone: ToneOption.classicAlarm,
      snoozeMinutes: 5,
    ),
  ),
  RoutineTemplate(
    icon: Icons.videocam_outlined,
    title: 'Meeting prep',
    subtitle: 'A spoken nudge before you need to join.',
    color: AppColors.amber,
    draft: ReminderDraft(
      title: 'Meeting prep',
      type: ReminderType.meeting,
      deliveryMode: DeliveryMode.speaking,
      repeatRule: 'Once',
      tone: ToneOption.morningBell,
      spokenMessage: 'Your meeting starts soon.',
      snoozeMinutes: 5,
    ),
  ),
  RoutineTemplate(
    icon: Icons.coffee_outlined,
    title: 'Deep work break',
    subtitle: 'A reliable interruption after a focused sprint.',
    color: AppColors.sage,
    draft: ReminderDraft(
      title: 'Deep work break',
      type: ReminderType.breakTime,
      deliveryMode: DeliveryMode.alarm,
      repeatRule: 'Every 120 min',
      tone: ToneOption.digitalBeep,
      snoozeMinutes: 10,
    ),
  ),
];

class RoutinePreset extends StatelessWidget {
  const RoutinePreset({super.key, required this.template, required this.onTap});

  final RoutineTemplate template;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  color: template.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(template.icon, color: template.color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      template.subtitle,
                      style: _subtle(context, small: true),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _TinyBadge(
                          label: _deliveryShortLabel(
                            template.draft.deliveryMode,
                          ),
                          color: _deliveryAccent(template.draft.deliveryMode),
                          icon: _deliveryIcon(template.draft.deliveryMode),
                        ),
                        _TinyBadge(
                          label: template.draft.repeatRule,
                          color: AppColors.sage,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.sage),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.darkMode,
    required this.readiness,
    required this.onDarkModeChanged,
    required this.onOpenReliability,
  });

  final bool darkMode;
  final AlarmReadiness? readiness;
  final ValueChanged<bool> onDarkModeChanged;
  final VoidCallback onOpenReliability;

  @override
  Widget build(BuildContext context) {
    final ready = readiness?.isReady ?? false;
    final checking = readiness == null;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 36),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  color: AppColors.sageLight,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.settings_rounded,
                  color: AppColors.sage,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Settings',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Control reliability, reminders, and app preferences.',
                      style: _subtle(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Text('Reliability', style: _sectionLabel(context)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: ready ? AppColors.sageLight : AppColors.amberLight,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    ready ? Icons.verified_rounded : Icons.info_outline_rounded,
                    color: ready ? AppColors.sage : AppColors.amber,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      checking
                          ? 'Checking Reliable Alarm'
                          : ready
                          ? 'Reliable Alarm is ready'
                          : 'Reliable Alarm needs attention',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  _TinyBadge(
                    label: checking
                        ? 'Checking'
                        : ready
                        ? 'Ready'
                        : 'Review',
                    color: ready ? AppColors.sage : AppColors.amber,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                ready
                    ? 'Alarm Reminder and Speaking Alarm can use Android’s reliable alarm path on this device.'
                    : 'Review notifications, exact alarms, full-screen behavior, DND, and alarm volume before relying on important reminders.',
                style: const TextStyle(height: 1.35),
              ),
              const SizedBox(height: 14),
              FilledButton.tonalIcon(
                onPressed: onOpenReliability,
                icon: const Icon(Icons.shield_outlined),
                label: const Text('Review setup'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const SettingTile(
          icon: Icons.bug_report_outlined,
          title: 'Troubleshooting',
          subtitle: 'Debug/status screen coming soon',
        ),
        const SizedBox(height: 30),
        Text('Reminder behavior', style: _sectionLabel(context)),
        const SizedBox(height: 10),
        const SettingTile(
          icon: Icons.notifications_active_outlined,
          title: 'Reminder types',
          subtitle: 'Gentle, Alarm, and Speaking reminders',
        ),
        const SizedBox(height: 10),
        const SettingTile(
          icon: Icons.volume_up_outlined,
          title: 'Voice and sound',
          subtitle: 'Built-in tones · Spoken messages',
        ),
        const SizedBox(height: 30),
        Text('Integrations', style: _sectionLabel(context)),
        const SizedBox(height: 10),
        const SettingTile(
          icon: Icons.calendar_month_outlined,
          title: 'Google Calendar',
          subtitle: 'Meeting reminders planned for Phase 4',
        ),
        const SizedBox(height: 10),
        const SettingTile(
          icon: Icons.video_call_outlined,
          title: 'Microsoft Teams / Outlook',
          subtitle: 'Calendar support planned after Google Calendar',
        ),
        const SizedBox(height: 30),
        Text('Preferences', style: _sectionLabel(context)),
        const SizedBox(height: 10),
        Material(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          child: SwitchListTile.adaptive(
            value: darkMode,
            onChanged: onDarkModeChanged,
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text(
              'Dark mode',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: const Text('Use a calmer dark appearance'),
          ),
        ),
        const SizedBox(height: 10),
        const SettingTile(
          icon: Icons.person_outline_rounded,
          title: 'Sync account',
          subtitle: 'Coming later for multi-device reminders',
        ),
      ],
    );
  }
}

class SettingTile extends StatelessWidget {
  const SettingTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

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
        trailing: onTap == null
            ? null
            : const Icon(Icons.chevron_right_rounded),
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

class _ReliabilityScreenState extends State<ReliabilityScreen>
    with WidgetsBindingObserver {
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
                      Icon(
                        ready
                            ? Icons.verified_rounded
                            : Icons.info_outline_rounded,
                        color: ready ? AppColors.sage : AppColors.amber,
                        size: 28,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        ready
                            ? 'Reliable Alarm is ready'
                            : 'Finish setup for Reliable Alarm',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        ready
                            ? 'Important reminders can use Android’s alarm channel and spoken voice.'
                            : 'Complete each item below before relying on a spoken alarm.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                if (_error != null)
                  Text('Unable to read device status: $_error'),
                _ReadinessItem(
                  title: 'Notifications',
                  detail: 'Allow Speaking Clock notifications',
                  ready: _readiness?.notificationsEnabled ?? false,
                  action: () =>
                      _perform(ReliabilityPlatform.requestNotifications),
                  actionLabel: 'Allow',
                ),
                _ReadinessItem(
                  title: 'Exact alarms',
                  detail: 'Let important alarms fire at their exact time',
                  ready: _readiness?.exactAlarmEnabled ?? false,
                  action: () =>
                      _perform(ReliabilityPlatform.requestExactAlarms),
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
                  action: () => _perform(
                    ReliabilityPlatform.openFullScreenIntentSettings,
                  ),
                  actionLabel: 'Open settings',
                ),
                _ReadinessItem(
                  title: 'Alarm volume',
                  detail: 'Keep alarm volume above the lowest level',
                  ready: _readiness?.alarmVolumeEnabled ?? false,
                  action: _refresh,
                  actionLabel: 'Check again',
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Refresh device status'),
                ),
              ],
            ),
    );
  }
}

class _ReadinessItem extends StatelessWidget {
  const _ReadinessItem({
    required this.title,
    required this.detail,
    required this.ready,
    required this.action,
    required this.actionLabel,
  });

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
          leading: Icon(
            ready ? Icons.check_circle_rounded : Icons.circle_outlined,
            color: ready ? AppColors.sage : AppColors.amber,
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(detail),
          trailing: ready
              ? const Text(
                  'Ready',
                  style: TextStyle(
                    color: AppColors.sage,
                    fontWeight: FontWeight.w800,
                  ),
                )
              : TextButton(onPressed: action, child: Text(actionLabel)),
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
          IconButton(
            tooltip: 'Edit reminder',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
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
          Text(
            reminder.title,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            reminder.time,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 28),
          _DetailCard(label: 'Schedule', value: reminder.detail),
          const SizedBox(height: 10),
          _DetailCard(
            label: 'Delivery',
            value: _deliveryLabel(reminder.deliveryMode),
          ),
          const SizedBox(height: 10),
          _DetailCard(label: 'Tone', value: _toneLabel(reminder.tone)),
          if (reminder.isSpeakingAlarm) ...[
            const SizedBox(height: 10),
            _DetailCard(
              label: 'Spoken message',
              value: reminder.spokenMessage.isEmpty
                  ? 'It is time for ${reminder.title}'
                  : reminder.spokenMessage,
            ),
          ],
          const SizedBox(height: 10),
          Material(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            child: SwitchListTile.adaptive(
              value: reminder.enabled,
              onChanged: onToggleEnabled,
              secondary: Icon(
                reminder.enabled
                    ? Icons.play_circle_outline_rounded
                    : Icons.pause_circle_outline_rounded,
              ),
              title: const Text(
                'Enabled',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                reminder.enabled
                    ? 'This reminder can fire'
                    : 'Paused reminders stay saved but do not fire',
              ),
            ),
          ),
          const SizedBox(height: 28),
          if (reminder.type == ReminderType.meeting)
            FilledButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Meeting links will be connected with Google Calendar setup.',
                  ),
                ),
              ),
              icon: const Icon(Icons.videocam_rounded),
              label: const Text('Join meeting'),
            )
          else
            FilledButton.tonalIcon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Snoozed for 10 minutes.')),
              ),
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
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
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
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: _sectionLabel(context)),
          const SizedBox(height: 6),
          Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
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
          Icon(
            isTomorrow
                ? Icons.info_outline_rounded
                : Icons.check_circle_outline_rounded,
            size: 18,
            color: isTomorrow ? AppColors.amber : AppColors.sage,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isTomorrow ? AppColors.amber : AppColors.sage,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ReminderEditor extends StatefulWidget {
  const ReminderEditor({
    super.key,
    required this.initialType,
    this.reminder,
    this.draft,
  });

  final ReminderType initialType;
  final Reminder? reminder;
  final ReminderDraft? draft;

  @override
  State<ReminderEditor> createState() => _ReminderEditorState();
}

class _ReminderEditorState extends State<ReminderEditor> {
  final _controller = TextEditingController();
  final _spokenController = TextEditingController();
  final _customRepeatController = TextEditingController(text: '30');
  static const _repeatOptions = [
    'Once',
    'Every day',
    'Weekdays',
    'Custom minutes',
  ];
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

  bool get _canSave => _controller.text.trim().isNotEmpty;

  String get _fallbackSpokenMessage {
    final title = _controller.text.trim();
    return 'It is time for ${title.isEmpty ? 'this reminder' : title}.';
  }

  DateTime get _selectedTriggerAt {
    return _triggerForTime(_time);
  }

  @override
  void initState() {
    super.initState();
    final reminder = widget.reminder;
    final draft = widget.draft;
    _type = reminder?.type ?? draft?.type ?? widget.initialType;
    _deliveryMode =
        reminder?.deliveryMode ?? draft?.deliveryMode ?? DeliveryMode.gentle;
    _tone = reminder?.tone ?? draft?.tone ?? ToneOption.softChime;
    _time = _defaultReminderTime();
    _snoozeMinutes = reminder?.snoozeMinutes ?? draft?.snoozeMinutes ?? 10;
    if (draft != null && reminder == null) {
      _controller.text = draft.title;
      _spokenController.text = draft.spokenMessage;
      _applyRepeatRule(draft.repeatRule);
    }
    if (reminder != null) {
      _controller.text = reminder.title;
      _spokenController.text = reminder.spokenMessage;
      _applyRepeatRule(reminder.detail.split(' · ').first);
      _time = _parseTimeLabel(reminder.time) ?? _time;
    }
  }

  void _applyRepeatRule(String repeatRule) {
    final customMinutes = _customRepeatMinutesFromRule(repeatRule);
    if (customMinutes != null) {
      _frequency = 'Custom minutes';
      _customRepeatController.text = '$customMinutes';
    } else {
      _frequency = _repeatOptions.contains(repeatRule)
          ? repeatRule
          : 'Every day';
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
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked != null) setState(() => _time = picked);
  }

  void _save() {
    if (!_canSave) return;
    final title = _controller.text.trim();
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
        createdAtMillis:
            reminder?.createdAtMillis ?? now.millisecondsSinceEpoch,
        updatedAtMillis: now.millisecondsSinceEpoch,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.reminder != null;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(20, 12, 20, bottomInset + 18),
        decoration: BoxDecoration(
          color: AppColors.canvas,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  height: 4,
                  width: 42,
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 46,
                    width: 46,
                    decoration: BoxDecoration(
                      color: AppColors.sageLight,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.add_alarm_rounded,
                      color: AppColors.sage,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          editing ? 'Edit reminder' : 'Create reminder',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Choose how Speaking Clock should get your attention.',
                          style: _subtle(context),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _EditorCard(
                title: 'What should I remind you about?',
                icon: Icons.edit_note_rounded,
                child: TextField(
                  controller: _controller,
                  autofocus: !editing,
                  onChanged: (_) => setState(() {}),
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Drink water',
                    errorText: _controller.text.isEmpty
                        ? null
                        : _canSave
                        ? null
                        : 'Add a title before saving.',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _EditorCard(
                title: 'Reminder category',
                icon: Icons.category_outlined,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ReminderType.values
                      .map(
                        (type) => ChoiceChip(
                          label: Text(_label(type)),
                          selected: type == _type,
                          onSelected: (_) => setState(() => _type = type),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 14),
              _EditorCard(
                title: 'First reminder',
                icon: Icons.schedule_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OutlinedButton(
                      onPressed: _pickTime,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(72),
                        alignment: Alignment.centerLeft,
                        side: const BorderSide(color: AppColors.line),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        backgroundColor: Colors.white,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.sageLight,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.access_time_rounded,
                              color: AppColors.sage,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              _formatTime12(_time),
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.ink,
                                  ),
                            ),
                          ),
                          const Icon(Icons.keyboard_arrow_down_rounded),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    _SchedulePreview(
                      triggerAt: _selectedTriggerAt,
                      customRepeatMinutes: _frequency == 'Custom minutes'
                          ? _customRepeatMinutes
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _EditorCard(
                title: 'Repeat',
                icon: Icons.repeat_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _repeatOptions
                          .map(
                            (option) => ChoiceChip(
                              label: Text(option),
                              selected: option == _frequency,
                              onSelected: (_) =>
                                  setState(() => _frequency = option),
                            ),
                          )
                          .toList(),
                    ),
                    if (_frequency == 'Custom minutes') ...[
                      const SizedBox(height: 14),
                      TextField(
                        controller: _customRepeatController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Repeat every',
                          suffixText: 'minutes',
                          helperText:
                              'First fire stays at ${_formatTime12(_time)}, then repeats every $_customRepeatMinutes min.',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _EditorCard(
                title: 'How should it remind you?',
                icon: Icons.notifications_active_outlined,
                child: Column(
                  children: DeliveryMode.values
                      .map(
                        (mode) => Padding(
                          padding: EdgeInsets.only(
                            bottom: mode == DeliveryMode.values.last ? 0 : 10,
                          ),
                          child: _DeliveryModeCard(
                            mode: mode,
                            selected: _deliveryMode == mode,
                            onTap: () => setState(() => _deliveryMode = mode),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              if (_deliveryMode == DeliveryMode.speaking) ...[
                const SizedBox(height: 14),
                _EditorCard(
                  title: 'What should it say?',
                  icon: Icons.record_voice_over_outlined,
                  child: TextField(
                    controller: _spokenController,
                    minLines: 2,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Drink water now.',
                      helperText:
                          'If left empty, it will say: "$_fallbackSpokenMessage"',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              _EditorCard(
                title: 'Tone',
                icon: Icons.music_note_rounded,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ToneOption.values
                      .map(
                        (tone) => ChoiceChip(
                          avatar: Icon(_toneIcon(tone), size: 18),
                          label: Text(_toneLabel(tone)),
                          selected: tone == _tone,
                          onSelected: (_) => setState(() => _tone = tone),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 14),
              _EditorCard(
                title: _deliveryMode == DeliveryMode.gentle
                    ? 'Remind again after'
                    : 'Snooze',
                icon: _deliveryMode == DeliveryMode.gentle
                    ? Icons.more_time_rounded
                    : Icons.snooze_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _deliveryMode == DeliveryMode.gentle
                          ? 'Used when you tap “Remind again” on the gentle notification.'
                          : 'Used when you snooze the full-screen alarm or alarm notification.',
                      style: _subtle(context),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [2, 5, 10, 15, 30]
                          .map(
                            (value) => ChoiceChip(
                              label: Text('$value min'),
                              selected: value == _snoozeMinutes,
                              onSelected: (_) =>
                                  setState(() => _snoozeMinutes = value),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (!_canSave)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Add a reminder title before saving.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _canSave ? _save : null,
                  icon: const Icon(Icons.check_rounded),
                  label: Text(editing ? 'Save changes' : 'Save reminder'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditorCard extends StatelessWidget {
  const _EditorCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.sageLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.sage, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _DeliveryModeCard extends StatelessWidget {
  const _DeliveryModeCard({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final DeliveryMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = switch (mode) {
      DeliveryMode.gentle => Icons.notifications_none_rounded,
      DeliveryMode.alarm => Icons.alarm_rounded,
      DeliveryMode.speaking => Icons.record_voice_over_rounded,
    };
    final description = switch (mode) {
      DeliveryMode.gentle => 'A light notification for low-urgency nudges.',
      DeliveryMode.alarm => 'Rings until you acknowledge it.',
      DeliveryMode.speaking =>
        'Speaks your message, then rings until acknowledged.',
    };
    final badges = switch (mode) {
      DeliveryMode.gentle => const ['Light', 'Notification'],
      DeliveryMode.alarm => const ['Full-screen', 'Acknowledge'],
      DeliveryMode.speaking => const ['Speaks', 'Full-screen'],
    };
    final accent = switch (mode) {
      DeliveryMode.gentle => const Color(0xff7aa0a8),
      DeliveryMode.alarm => AppColors.sage,
      DeliveryMode.speaking => AppColors.amber,
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.11) : AppColors.canvas,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? accent : AppColors.line,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _deliveryLabel(mode),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: AppColors.ink,
                              ),
                        ),
                      ),
                      if (selected)
                        Icon(
                          Icons.check_circle_rounded,
                          color: accent,
                          size: 20,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(description, style: _subtle(context)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: badges
                        .map(
                          (badge) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              badge,
                              style: TextStyle(
                                color: accent,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

TextStyle _sectionLabel(BuildContext context) =>
    Theme.of(context).textTheme.labelMedium!.copyWith(
      letterSpacing: 1.2,
      fontWeight: FontWeight.w800,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
TextStyle _subtle(BuildContext context, {bool small = false}) =>
    (small
            ? Theme.of(context).textTheme.bodySmall
            : Theme.of(context).textTheme.bodyMedium)!
        .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);

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

String _deliveryShortLabel(DeliveryMode mode) => switch (mode) {
  DeliveryMode.gentle => 'Gentle',
  DeliveryMode.alarm => 'Alarm',
  DeliveryMode.speaking => 'Speaking',
};

IconData _deliveryIcon(DeliveryMode mode) => switch (mode) {
  DeliveryMode.gentle => Icons.notifications_none_rounded,
  DeliveryMode.alarm => Icons.alarm_rounded,
  DeliveryMode.speaking => Icons.record_voice_over_rounded,
};

Color _deliveryAccent(DeliveryMode mode) => switch (mode) {
  DeliveryMode.gentle => const Color(0xff7aa0a8),
  DeliveryMode.alarm => AppColors.sage,
  DeliveryMode.speaking => AppColors.amber,
};

String _toneLabel(ToneOption tone) => switch (tone) {
  ToneOption.softChime => 'Soft Chime',
  ToneOption.classicAlarm => 'Classic Alarm',
  ToneOption.digitalBeep => 'Digital Beep',
  ToneOption.morningBell => 'Morning Bell',
  ToneOption.calmWater => 'Calm Water',
  ToneOption.vibrationOnly => 'Vibration Only',
};

IconData _toneIcon(ToneOption tone) => switch (tone) {
  ToneOption.softChime => Icons.notifications_none_rounded,
  ToneOption.classicAlarm => Icons.alarm_rounded,
  ToneOption.digitalBeep => Icons.graphic_eq_rounded,
  ToneOption.morningBell => Icons.wb_sunny_outlined,
  ToneOption.calmWater => Icons.water_drop_outlined,
  ToneOption.vibrationOnly => Icons.vibration_rounded,
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

String _greeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}

String _scheduleBlockedMessage(Reminder reminder, AlarmReadiness readiness) {
  if (!readiness.notificationsEnabled) {
    return 'Reminder saved, but notifications are off. Allow notifications before it can fire.';
  }
  if (!readiness.exactAlarmEnabled) {
    return 'Reminder saved, but exact alarms are off. Allow exact alarms before it can fire on time.';
  }
  if (reminder.isAlarm && !readiness.alarmVolumeEnabled) {
    return 'Reminder saved, but alarm volume is muted or too low. Raise alarm volume before relying on ${_deliveryLabel(reminder.deliveryMode)}.';
  }
  return 'Reminder saved, but this device is not ready to schedule it yet.';
}

String _friendlyDate(DateTime date) {
  const weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
}

List<String> _readinessWarnings(AlarmReadiness? readiness) {
  if (readiness == null) return const [];
  final warnings = <String>[];
  if (!readiness.notificationsEnabled) {
    warnings.add('Notifications are off, so reminders may not appear.');
  }
  if (!readiness.exactAlarmEnabled) {
    warnings.add(
      'Exact alarms are off, so important alarms may not fire on time.',
    );
  }
  if (!readiness.fullScreenIntentEnabled) {
    warnings.add(
      'Full-screen alarms are off, so lock-screen alarm screens may not appear.',
    );
  }
  if (!readiness.alarmVolumeEnabled) {
    warnings.add(
      'Alarm volume is muted or too low, so speech and alarm sound may not be audible.',
    );
  }
  if (!readiness.dndPolicyAccess) {
    warnings.add(
      'Reliable alarms cannot interrupt DND. Android alarms may still fire, but allow this for the safest DND behavior.',
    );
  }
  return warnings;
}

TimeOfDay _defaultReminderTime() {
  final now = DateTime.now().add(const Duration(minutes: 5));
  return TimeOfDay(hour: now.hour, minute: now.minute);
}

DateTime _triggerForTime(TimeOfDay time) {
  final now = DateTime.now();
  var triggerAt = DateTime(
    now.year,
    now.month,
    now.day,
    time.hour,
    time.minute,
  );
  if (!triggerAt.isAfter(now)) {
    triggerAt = triggerAt.add(const Duration(days: 1));
  }
  return triggerAt;
}

String _formatTime12(TimeOfDay time) {
  final period = time.hour >= 12 ? 'PM' : 'AM';
  final hour12 = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour12:$minute $period';
}

int? _customRepeatMinutesFromRule(String rule) {
  final match = RegExp(
    r'^Every\s+(\d+)\s+min$',
    caseSensitive: false,
  ).firstMatch(rule.trim());
  if (match == null) return null;
  final minutes = int.tryParse(match.group(1) ?? '');
  if (minutes == null || minutes <= 0) return null;
  return minutes;
}

TimeOfDay? _parseTimeLabel(String value) {
  final normalized = value.trim().toUpperCase();
  final match = RegExp(
    r'^(\d{1,2}):(\d{2})(?:\s*(AM|PM))?$',
  ).firstMatch(normalized);
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
