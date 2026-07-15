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

  void _goTo(int page) {
    _controller.animateToPage(
      page,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _next() {
    if (_page == 3) {
      widget.onComplete();
      return;
    }
    _goTo(_page + 1);
  }

  @override
  Widget build(BuildContext context) {
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
                    if (_page > 0)
                      IconButton(
                        onPressed: () => _goTo(_page - 1),
                        icon: const Icon(Icons.arrow_back_rounded),
                        color: AppColors.ink,
                      )
                    else
                      const SizedBox(width: 48),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ],
                ),
                Expanded(
                  child: PageView(
                    controller: _controller,
                    onPageChanged: (value) => setState(() => _page = value),
                    children: [
                      _WelcomeOnboardingPage(onNext: _next),
                      _IntensitiesOnboardingPage(onNext: _next),
                      _ReliableOnboardingPage(
                        readiness: _readiness,
                        loading: _loading,
                        onNotifications: () =>
                            _run(ReliabilityPlatform.requestNotifications),
                        onExactAlarms: () =>
                            _run(ReliabilityPlatform.requestExactAlarms),
                        onFullScreen: () => _run(
                          ReliabilityPlatform.openFullScreenIntentSettings,
                        ),
                        onDnd: () => _run(ReliabilityPlatform.openDndSettings),
                        onVolume: () => _run(_refresh),
                        onNext: _next,
                      ),
                      _ReadyOnboardingPage(onNext: _next),
                    ],
                  ),
                ),
                _OnboardingDots(current: _page, count: 4),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomeOnboardingPage extends StatelessWidget {
  const _WelcomeOnboardingPage({required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return _OnboardingShell(
      top: const Text('Welcome to', style: TextStyle(fontSize: 20)),
      title: 'Speaking Clock',
      body:
          'Your calm companion for reminders that speak, ring, and keep you on track.',
      art: const _HeroIconBubble(
        icon: SpeakingClockIcon.bell,
        color: AppColors.linen,
        gradient: AppColors.signatureHeroGradient,
        size: 152,
        iconSize: 76,
      ),
      primaryLabel: 'Next',
      onPrimary: onNext,
    );
  }
}

class _IntensitiesOnboardingPage extends StatelessWidget {
  const _IntensitiesOnboardingPage({required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return _OnboardingShell(
      title: 'Reminder intensities',
      body: 'Choose how you want to be reminded.',
      content: const Column(
        children: [
          _IntensityTile(
            icon: SpeakingClockIcon.droplet,
            title: 'Gentle reminder',
            body: 'A soft notification to nudge you.',
            color: AppColors.darkWine,
          ),
          SizedBox(height: 12),
          _IntensityTile(
            icon: SpeakingClockIcon.bell,
            title: 'Alarm reminder',
            body: 'A reliable alarm to get your attention.',
            color: AppColors.darkWine,
          ),
          SizedBox(height: 12),
          _IntensityTile(
            icon: SpeakingClockIcon.speaker,
            title: 'Speaking reminder',
            body: 'An alarm that speaks a message aloud.',
            color: AppColors.darkWine,
          ),
        ],
      ),
      primaryLabel: 'Next',
      onPrimary: onNext,
    );
  }
}

class _ReliableOnboardingPage extends StatelessWidget {
  const _ReliableOnboardingPage({
    required this.readiness,
    required this.loading,
    required this.onNotifications,
    required this.onExactAlarms,
    required this.onFullScreen,
    required this.onDnd,
    required this.onVolume,
    required this.onNext,
  });

  final AlarmReadiness? readiness;
  final bool loading;
  final VoidCallback onNotifications;
  final VoidCallback onExactAlarms;
  final VoidCallback onFullScreen;
  final VoidCallback onDnd;
  final VoidCallback onVolume;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final allReady =
        readiness?.notificationsEnabled == true &&
        readiness?.exactAlarmEnabled == true &&
        readiness?.fullScreenIntentEnabled == true &&
        readiness?.dndPolicyAccess == true &&
        readiness?.alarmVolumeEnabled == true;
    return _OnboardingShell(
      title: 'Reliable reminders',
      body: 'Speaking Clock uses these features to keep you on time.',
      content: Column(
        children: [
          _ReliableFeatureRow(
            icon: SpeakingClockIcon.shield,
            title: 'Notifications',
            body: 'Send you reminders',
            ready: readiness?.notificationsEnabled == true,
            actionLabel: 'Allow',
            onTap: onNotifications,
          ),
          _ReliableFeatureRow(
            icon: SpeakingClockIcon.bell,
            title: 'Exact alarms (Android)',
            body: 'Fire at the exact time',
            ready: readiness?.exactAlarmEnabled == true,
            actionLabel: 'Allow',
            onTap: onExactAlarms,
          ),
          _ReliableFeatureRow(
            icon: SpeakingClockIcon.target,
            title: 'Full-screen alarms',
            body: 'Make alarms hard to miss',
            ready: readiness?.fullScreenIntentEnabled == true,
            actionLabel: 'Open',
            onTap: onFullScreen,
          ),
          _ReliableFeatureRow(
            icon: SpeakingClockIcon.shield,
            title: 'Do Not Disturb access',
            body: 'Allow reminders to break through',
            ready: readiness?.dndPolicyAccess == true,
            actionLabel: 'Open',
            onTap: onDnd,
          ),
          _ReliableFeatureRow(
            icon: SpeakingClockIcon.speaker,
            title: 'Alarm volume',
            body: 'Ensure alarms are audible',
            ready: readiness?.alarmVolumeEnabled == true,
            actionLabel: 'Check',
            onTap: onVolume,
          ),
        ],
      ),
      primaryLabel: allReady ? 'Continue' : 'Complete setup above',
      loading: loading,
      onPrimary: allReady ? onNext : null,
    );
  }
}

class _ReadyOnboardingPage extends StatelessWidget {
  const _ReadyOnboardingPage({required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return _OnboardingShell(
      art: const _HeroIconBubble(
        icon: SpeakingClockIcon.shield,
        color: Colors.white,
        gradient: AppColors.signatureHeroGradient,
        size: 128,
        iconSize: 58,
      ),
      title: 'You are ready!',
      body: 'We’ll keep everything running smoothly in the background.',
      content: Text(
        'You can review or change these settings anytime in Reliability.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.ink.withValues(alpha: 0.74),
          fontWeight: FontWeight.w700,
          height: 1.35,
        ),
      ),
      primaryLabel: 'Let’s go',
      onPrimary: onNext,
    );
  }
}

class _OnboardingShell extends StatelessWidget {
  const _OnboardingShell({
    required this.title,
    required this.body,
    required this.primaryLabel,
    required this.onPrimary,
    this.top,
    this.art,
    this.content,
    this.loading = false,
  });

  final Widget? top;
  final Widget? art;
  final String title;
  final String body;
  final Widget? content;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (top != null) ...[top!, const SizedBox(height: 4)],
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.darkWine,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    body,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.ink.withValues(alpha: 0.78),
                      height: 1.45,
                    ),
                  ),
                  if (art != null) ...[const SizedBox(height: 34), art!],
                  if (content != null) ...[
                    const SizedBox(height: 32),
                    content!,
                  ],
                  const SizedBox(height: 34),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: loading ? null : onPrimary,
                      child: loading
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(primaryLabel),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HeroIconBubble extends StatelessWidget {
  const _HeroIconBubble({
    required this.icon,
    required this.color,
    required this.gradient,
    required this.size,
    required this.iconSize,
  });

  final SpeakingClockIcon icon;
  final Color color;
  final Gradient gradient;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        gradient: gradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.darkWine.withValues(alpha: 0.14),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Center(
        child: CustomReminderIcon(icon: icon, color: color, size: iconSize),
      ),
    );
  }
}

class _MiniGradientIconBubble extends StatelessWidget {
  const _MiniGradientIconBubble({required this.icon, required this.foreground});

  final SpeakingClockIcon icon;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 66,
      width: 66,
      decoration: BoxDecoration(
        gradient: AppColors.signatureHeroGradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.darkWine.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: CustomReminderIcon(icon: icon, color: foreground, size: 32),
      ),
    );
  }
}

class _IntensityTile extends StatelessWidget {
  const _IntensityTile({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });

  final SpeakingClockIcon icon;
  final String title;
  final String body;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          _MiniGradientIconBubble(icon: icon, foreground: Colors.white),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color == AppColors.darkWine
                        ? AppColors.darkWine
                        : AppColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(body, style: _subtle(context, small: true)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReliableFeatureRow extends StatelessWidget {
  const _ReliableFeatureRow({
    required this.icon,
    required this.title,
    required this.body,
    required this.ready,
    required this.actionLabel,
    this.onTap,
  });

  final SpeakingClockIcon icon;
  final String title;
  final String body;
  final bool ready;
  final String actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: AppColors.linen.withValues(alpha: 0.54),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: CustomReminderIcon(
                  icon: icon,
                  color: ready ? AppColors.sage : AppColors.darkWine,
                  size: 21,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 2),
                  Text(body, style: _subtle(context, small: true)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (ready)
              const Text(
                'Ready',
                style: TextStyle(
                  color: AppColors.sage,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              )
            else
              TextButton(
                onPressed: onTap,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.darkWine,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 36),
                ),
                child: Text(actionLabel),
              ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingDots extends StatelessWidget {
  const _OnboardingDots({required this.current, required this.count});

  final int current;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final active = index == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 9,
          width: active ? 18 : 9,
          decoration: BoxDecoration(
            color: active
                ? AppColors.darkWine
                : AppColors.ink.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(99),
          ),
        );
      }),
    );
  }
}
