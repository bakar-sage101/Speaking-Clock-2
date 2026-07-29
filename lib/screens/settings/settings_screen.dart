part of '../../main.dart';

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
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 130),
      children: [
        Text(
          'Settings',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppColors.darkWine,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Control reliability, reminders, and preferences.',
          style: _subtle(context),
        ),
        const SizedBox(height: 24),
        Text('Reliability', style: _sectionLabel(context)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _fillFor(ready ? AppColors.gentle : AppColors.alarm),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    ready ? Icons.verified_rounded : Icons.info_outline_rounded,
                    color: _onFill(ready ? AppColors.gentle : AppColors.alarm),
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
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ).copyWith(color: AppColors.bone),
                    ),
                  ),
                  _TinyBadge(
                    label: checking
                        ? 'Checking'
                        : ready
                        ? 'Ready'
                        : 'Review',
                    color: AppColors.linen,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                ready
                    ? 'Alarm Reminder and Speaking Alarm can use Android’s reliable alarm path on this device.'
                    : 'Review notifications, exact alarms, full-screen behavior, DND, and alarm volume before relying on important reminders.',
                style: TextStyle(
                  height: 1.35,
                  color: AppColors.bone.withValues(alpha: 0.72),
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: onOpenReliability,
                icon: const Icon(Icons.shield_outlined, size: 18),
                label: const Text('Review setup'),
                style: FilledButton.styleFrom(
                  backgroundColor: _onFill(ready ? AppColors.gentle : AppColors.alarm),
                  foregroundColor: AppColors.surface,
                  textStyle: const TextStyle(fontWeight: FontWeight.w800),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SettingTile(
          icon: Icons.shield_outlined,
          title: 'Reliable alarm setup',
          subtitle: 'Review and configure',
          onTap: onOpenReliability,
          color: AppColors.gentle,
        ),
        const SizedBox(height: 30),
        Text('Reminder behavior', style: _sectionLabel(context)),
        const SizedBox(height: 10),
        SettingTile(
          icon: Icons.notifications_active_outlined,
          title: 'Reminder types',
          subtitle: 'Gentle, Alarm, and Speaking reminders',
          color: AppColors.alarm,
        ),
        const SizedBox(height: 10),
        SettingTile(
          icon: Icons.volume_up_outlined,
          title: 'Voice and sound',
          subtitle: 'Built-in tones · Spoken messages',
          color: AppColors.speaking,
        ),
        const SizedBox(height: 30),
        Text('Integrations', style: _sectionLabel(context)),
        const SizedBox(height: 10),
        SettingTile(
          icon: Icons.calendar_month_outlined,
          title: 'Google Calendar',
          subtitle: 'Meeting reminders planned for Phase 4',
          color: AppColors.gentle,
        ),
        const SizedBox(height: 10),
        SettingTile(
          icon: Icons.video_call_outlined,
          title: 'Microsoft Teams / Outlook',
          subtitle: 'Calendar support planned after Google Calendar',
          color: AppColors.speaking,
        ),
        const SizedBox(height: 30),
        Text('Preferences', style: _sectionLabel(context)),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: _fillFor(AppColors.brass),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.line),
          ),
          child: SwitchListTile.adaptive(
            value: darkMode,
            onChanged: onDarkModeChanged,
            activeThumbColor: AppColors.surface,
            activeTrackColor: _onFill(AppColors.brass),
            inactiveThumbColor: _onFill(AppColors.brass),
            inactiveTrackColor: AppColors.surface.withValues(alpha: 0.7),
            secondary: SizedBox(
              width: 40,
              child: Icon(Icons.dark_mode_outlined, color: _onFill(AppColors.brass), size: 26),
            ),
            title: Text(
              'Dark mode',
              style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.bone, fontSize: 15),
            ),
            subtitle: Text(
              'Use a calmer dark appearance',
              style: TextStyle(color: AppColors.bone.withValues(alpha: 0.6), fontSize: 12.5),
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        ),
        const SizedBox(height: 10),
        SettingTile(
          icon: Icons.person_outline_rounded,
          title: 'Sync account',
          subtitle: 'Coming later for multi-device reminders',
          color: AppColors.brass,
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
    this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.brass;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: _fillFor(c),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: Icon(icon, color: _onFill(c), size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.bone,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppColors.bone.withValues(alpha: 0.6),
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.bone.withValues(alpha: 0.5),
                ),
            ],
          ),
        ),
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
      appBar: AppBar(title: const Text('Reliable Alarm setup')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: _fillFor(ready ? AppColors.gentle : AppColors.alarm),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 58,
                        width: 58,
                        decoration: BoxDecoration(
                          color: _onFill(ready ? AppColors.gentle : AppColors.alarm)
                              .withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: CustomReminderIcon(
                            icon: SpeakingClockIcon.shield,
                            color: _onFill(ready ? AppColors.gentle : AppColors.alarm),
                            size: 30,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        ready
                            ? 'Reliable Alarm is ready'
                            : 'Finish setup for Reliable Alarm',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.bone,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        ready
                            ? 'Important reminders can use Android’s alarm channel and spoken voice.'
                            : 'Complete each item below before relying on a spoken alarm.',
                        style: TextStyle(
                          color: AppColors.bone.withValues(alpha: 0.72),
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                if (_error != null)
                  Text('Unable to read device status: $_error'),
                _ReadinessItem(
                  icon: Icons.notifications_active_outlined,
                  title: 'Notifications',
                  detail: 'Allow Speaking Clock notifications',
                  ready: _readiness?.notificationsEnabled ?? false,
                  action: () =>
                      _perform(ReliabilityPlatform.requestNotifications),
                  actionLabel: 'Allow',
                ),
                _ReadinessItem(
                  icon: Icons.alarm_rounded,
                  title: 'Exact alarms',
                  detail: 'Let important alarms fire at their exact time',
                  ready: _readiness?.exactAlarmEnabled ?? false,
                  action: () =>
                      _perform(ReliabilityPlatform.requestExactAlarms),
                  actionLabel: 'Allow',
                ),
                _ReadinessItem(
                  icon: Icons.do_not_disturb_on_outlined,
                  title: 'Do Not Disturb',
                  detail: 'Allow Reliable alarms to interrupt Do Not Disturb',
                  ready: _readiness?.dndPolicyAccess ?? false,
                  action: () => _perform(ReliabilityPlatform.openDndSettings),
                  actionLabel: 'Open channel',
                ),
                _ReadinessItem(
                  icon: Icons.fullscreen_rounded,
                  title: 'Full-screen alarms',
                  detail: 'Let alarms take over the lock screen',
                  ready: _readiness?.fullScreenIntentEnabled ?? false,
                  action: () => _perform(
                    ReliabilityPlatform.openFullScreenIntentSettings,
                  ),
                  actionLabel: 'Open settings',
                ),
                _ReadinessItem(
                  icon: Icons.volume_up_outlined,
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
    required this.icon,
    required this.title,
    required this.detail,
    required this.ready,
    required this.action,
    required this.actionLabel,
  });

  final IconData icon;
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
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: ready ? _fillFor(AppColors.gentle) : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 38,
                child: Icon(
                  icon,
                  color: ready ? _onFill(AppColors.gentle) : AppColors.boneDim,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: AppColors.bone,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      detail,
                      style: TextStyle(
                        color: AppColors.bone.withValues(alpha: 0.72),
                        height: 1.3,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (ready)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Text(
                    'Ready',
                    style: TextStyle(
                      color: AppColors.bone,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                )
              else
                TextButton(onPressed: action, child: Text(actionLabel)),
            ],
          ),
        ),
      ),
    );
  }
}
