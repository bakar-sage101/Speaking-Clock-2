part of '../main.dart';

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
      enableDrag: true,
      isDismissible: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.88,
        alignment: Alignment.bottomCenter,
        child: ReminderEditor(initialType: initialType, draft: draft),
      ),
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
      enableDrag: true,
      isDismissible: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.88,
        alignment: Alignment.bottomCenter,
        child: ReminderEditor(initialType: original.type, reminder: original),
      ),
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
      seedColor: AppColors.auraMagenta,
      brightness: Brightness.dark,
    );
    return MaterialApp(
      title: 'Speaking Clock',
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey,
      scaffoldMessengerKey: _messengerKey,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme.copyWith(
          primary: AppColors.bone,
          onPrimary: AppColors.ink,
          secondary: AppColors.boneDim,
          surface: AppColors.surface,
          surfaceContainerHighest: AppColors.surfaceRaised,
          onSurface: AppColors.bone,
          onSurfaceVariant: AppColors.boneDim,
          outline: AppColors.line,
          error: AppColors.destructive,
        ),
        scaffoldBackgroundColor: AppColors.ink,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.ink,
          foregroundColor: AppColors.bone,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.surface.withValues(alpha: 0.96),
          indicatorColor: AppColors.bone,
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              color: states.contains(WidgetState.selected)
                  ? AppColors.bone
                  : AppColors.boneDim,
              fontWeight: FontWeight.w800,
            ),
          ),
          iconTheme: WidgetStateProperty.resolveWith(
            (states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? AppColors.ink
                  : AppColors.boneDim,
            ),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.bone,
            foregroundColor: AppColors.ink,
            textStyle: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.bone,
            side: const BorderSide(color: AppColors.line),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.06),
          labelStyle: const TextStyle(color: AppColors.boneDim),
          hintStyle: const TextStyle(color: AppColors.boneDim),
          helperStyle: const TextStyle(color: AppColors.boneDim),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: AppColors.line),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: AppColors.line),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: AppColors.bone, width: 1.2),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.surfaceRaised,
          contentTextStyle: const TextStyle(color: AppColors.bone),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.brass,
          foregroundColor: Color(0xff1A1205),
        ),
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
                      backgroundColor: AppColors.brass,
                      foregroundColor: const Color(0xff1A1205),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add reminder'),
                    ),
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.endFloat,
              bottomNavigationBar: Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                child: _AuraBottomNav(
                  selectedIndex: _tab,
                  onSelected: (value) => setState(() => _tab = value),
                ),
              ),
            ),
    );
  }
}

class _AuraBottomNav extends StatelessWidget {
  const _AuraBottomNav({required this.selectedIndex, required this.onSelected});

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _items = [
    (Icons.schedule_outlined, Icons.schedule_rounded, 'Today'),
    (Icons.grid_view_outlined, Icons.grid_view_rounded, 'Routines'),
    (Icons.tune_outlined, Icons.tune_rounded, 'Setup'),
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(34),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(34),
            border: Border.all(color: AppColors.line),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.42),
                blurRadius: 26,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            children: [
              for (var i = 0; i < _items.length; i++)
                Expanded(
                  child: _AuraBottomNavItem(
                    icon: _items[i].$1,
                    selectedIcon: _items[i].$2,
                    label: _items[i].$3,
                    selected: i == selectedIndex,
                    onTap: () => onSelected(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuraBottomNavItem extends StatelessWidget {
  const _AuraBottomNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            selected ? selectedIcon : icon,
            color: selected ? AppColors.brass : AppColors.boneDim,
            size: 21,
          ),
          const SizedBox(height: 5),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontFamily: 'monospace',
              color: selected ? AppColors.bone : AppColors.boneDim,
              fontSize: 9,
              letterSpacing: 1.8,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
