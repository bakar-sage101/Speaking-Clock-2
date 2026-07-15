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
        SoftPanel(
          radius: 28,
          padding: const EdgeInsets.all(20),
          gradient: ready
              ? AppColors.signatureHeroGradient
              : const LinearGradient(
                  colors: [
                    AppColors.darkWine,
                    AppColors.blush,
                    AppColors.linen,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderColor: Colors.transparent,
          shadowOpacity: 0.11,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    ready ? Icons.verified_rounded : Icons.info_outline_rounded,
                    color: AppColors.linen,
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
                        color: AppColors.linen,
                      ).copyWith(shadows: _softTextShadow(opacity: 0.28)),
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
                  color: AppColors.linen.withValues(alpha: 0.82),
                  fontWeight: FontWeight.w700,
                  shadows: _softTextShadow(opacity: 0.24),
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: onOpenReliability,
                icon: const Icon(Icons.shield_outlined),
                label: const Text('Review setup'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.linen,
                  foregroundColor: AppColors.darkWine,
                  textStyle: const TextStyle(fontWeight: FontWeight.w900),
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
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: SoftPanel(
          radius: 22,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: AppColors.darkWine.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: AppColors.darkWine, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(subtitle, style: _subtle(context, small: true)),
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.darkWine,
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
                SoftPanel(
                  radius: 30,
                  padding: const EdgeInsets.all(22),
                  gradient: ready
                      ? AppColors.signatureHeroGradient
                      : const LinearGradient(
                          colors: [
                            AppColors.darkWine,
                            AppColors.blush,
                            AppColors.linen,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  borderColor: Colors.transparent,
                  shadowOpacity: 0.12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 58,
                        width: 58,
                        decoration: BoxDecoration(
                          color: AppColors.linen.withValues(alpha: 0.16),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: CustomReminderIcon(
                            icon: SpeakingClockIcon.shield,
                            color: AppColors.linen,
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
                          color: AppColors.linen,
                          fontWeight: FontWeight.w900,
                          shadows: _softTextShadow(opacity: 0.28),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        ready
                            ? 'Important reminders can use Android’s alarm channel and spoken voice.'
                            : 'Complete each item below before relying on a spoken alarm.',
                        style: TextStyle(
                          color: AppColors.linen.withValues(alpha: 0.82),
                          height: 1.35,
                          fontWeight: FontWeight.w700,
                          shadows: _softTextShadow(opacity: 0.22),
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
        child: SoftPanel(
          radius: 22,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: (ready ? AppColors.sage : AppColors.darkWine)
                      .withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: ready ? AppColors.sage : AppColors.darkWine,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(detail, style: _subtle(context, small: true)),
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
                    color: AppColors.sage.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Ready',
                    style: TextStyle(
                      color: AppColors.darkWine,
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
