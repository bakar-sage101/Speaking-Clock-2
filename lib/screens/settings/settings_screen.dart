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
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 36),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: AppColors.softCardGradient,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.line.withValues(alpha: 0.75)),
            boxShadow: [
              BoxShadow(
                color: AppColors.darkWine.withValues(alpha: 0.035),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  gradient: AppColors.heroGradient,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.settings_rounded,
                  color: AppColors.darkWine,
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
            gradient: ready
                ? AppColors.heroGradient
                : const LinearGradient(
                    colors: [AppColors.amberLight, AppColors.linen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: (ready ? AppColors.ashGrey : AppColors.mutedWine)
                  .withValues(alpha: 0.16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    ready ? Icons.verified_rounded : Icons.info_outline_rounded,
                    color: ready ? AppColors.darkWine : AppColors.mutedWine,
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
                    color: ready ? AppColors.darkWine : AppColors.mutedWine,
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
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: BoxDecoration(
              gradient: AppColors.softCardGradient,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.line.withValues(alpha: 0.72)),
            ),
            child: SwitchListTile.adaptive(
              value: darkMode,
              onChanged: onDarkModeChanged,
              secondary: const Icon(
                Icons.dark_mode_outlined,
                color: AppColors.darkWine,
              ),
              title: const Text(
                'Dark mode',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: const Text('Use a calmer dark appearance'),
            ),
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
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          gradient: AppColors.softCardGradient,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.line.withValues(alpha: 0.72)),
        ),
        child: ListTile(
          leading: Icon(icon, color: AppColors.darkWine),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(subtitle),
          trailing: onTap == null
              ? null
              : const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.darkWine,
                ),
          onTap: onTap,
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
      appBar: AppBar(title: const Text('Reliable Alarm')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: ready
                        ? AppColors.heroGradient
                        : const LinearGradient(
                            colors: [AppColors.amberLight, AppColors.linen],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: (ready ? AppColors.ashGrey : AppColors.mutedWine)
                          .withValues(alpha: 0.16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        ready
                            ? Icons.verified_rounded
                            : Icons.info_outline_rounded,
                        color: ready ? AppColors.darkWine : AppColors.mutedWine,
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
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            gradient: AppColors.softCardGradient,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.line.withValues(alpha: 0.72)),
          ),
          child: ListTile(
            leading: Icon(
              ready ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: ready ? AppColors.darkWine : AppColors.mutedWine,
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
                      color: AppColors.darkWine,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                : TextButton(onPressed: action, child: Text(actionLabel)),
          ),
        ),
      ),
    );
  }
}
