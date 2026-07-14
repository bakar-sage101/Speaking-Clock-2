part of '../../main.dart';

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
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.onboardingGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: (_page + 1) / pages.length,
                          minHeight: 5,
                          backgroundColor: AppColors.linen.withValues(
                            alpha: 0.42,
                          ),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.darkWine,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.brightSnow.withValues(alpha: 0.78),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${_page + 1}/${pages.length}',
                        style: const TextStyle(
                          color: AppColors.darkWine,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
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
                if (_page > 0)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => _controller.previousPage(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                      ),
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('Back'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.darkWine,
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 48),
              ],
            ),
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
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.brightSnow.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: AppColors.linen.withValues(alpha: 0.75)),
            boxShadow: [
              BoxShadow(
                color: AppColors.darkWine.withValues(alpha: 0.10),
                blurRadius: 34,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 94,
                height: 94,
                decoration: BoxDecoration(
                  gradient: ready
                      ? AppColors.heroGradient
                      : AppColors.softCardGradient,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: AppColors.line),
                ),
                child: Icon(
                  ready ? Icons.check_rounded : page.icon,
                  size: 42,
                  color: ready ? AppColors.ashGrey : AppColors.darkWine,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                page.title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                ),
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
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.darkWine,
                  ),
                  child: Text(page.secondaryLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
