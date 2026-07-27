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
      body: _OnboardingAuraBackground(
        page: _page,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(
              children: [
                _OnboardingProgressLine(current: _page, count: 4),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (_page > 0)
                      IconButton(
                        onPressed: () => _goTo(_page - 1),
                        icon: const Icon(Icons.arrow_back_rounded),
                        color: AppColors.bone,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingAuraBackground extends StatelessWidget {
  const _OnboardingAuraBackground({required this.page, required this.child});

  final int page;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dominant = switch (page) {
      0 => AppColors.auraMagenta,
      1 => AppColors.auraBlue,
      2 => AppColors.auraLime,
      _ => AppColors.auraMagenta,
    };
    final edge = switch (page) {
      0 => AppColors.auraBlue,
      1 => AppColors.auraMagenta,
      2 => AppColors.auraBlue,
      _ => AppColors.auraLime,
    };
    final center = switch (page) {
      0 => const Alignment(0.0, 0.22),
      1 => const Alignment(-0.25, -0.02),
      2 => const Alignment(-0.28, 0.02),
      _ => const Alignment(0.0, 0.0),
    };
    return Stack(
      children: [
        const Positioned.fill(child: ColoredBox(color: AppColors.ink)),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: center,
                radius: 0.9,
                colors: [
                  dominant.withValues(alpha: page == 2 ? 0.62 : 0.72),
                  dominant.withValues(alpha: 0.28),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.38, 0.72],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.92, -0.82),
                radius: 1.1,
                colors: [edge.withValues(alpha: 0.22), Colors.transparent],
                stops: const [0.0, 0.48],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.36),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.36),
                ],
              ),
            ),
          ),
        ),
        const Positioned.fill(
          child: IgnorePointer(child: CustomPaint(painter: _NoisePainter())),
        ),
        child,
      ],
    );
  }
}

class _OnboardingProgressLine extends StatelessWidget {
  const _OnboardingProgressLine({required this.current, required this.count});

  final int current;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(count, (index) {
        final active = index <= current;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            height: 4,
            margin: EdgeInsets.only(right: index == count - 1 ? 0 : 6),
            decoration: BoxDecoration(
              color: active
                  ? AppColors.bone
                  : AppColors.bone.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        );
      }),
    );
  }
}

class _WelcomeOnboardingPage extends StatelessWidget {
  const _WelcomeOnboardingPage({required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return _OnboardingShell(
      top: const Text(
        'S P E A K I N G',
        style: TextStyle(
          color: AppColors.boneDim,
          fontSize: 11,
          letterSpacing: 6,
          fontWeight: FontWeight.w800,
        ),
      ),
      title: 'Clock',
      body: 'A calm companion for the things that matter.',
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
      body: 'Three ways to reach you, depending on what matters.',
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
      title: 'Let reminders through',
      body:
          'Allow the essentials so alarms can speak, ring, and appear when needed.',
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
          color: AppColors.boneDim,
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
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: AppColors.bone,
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic,
                      letterSpacing: -0.8,
                      shadows: _softTextShadow(opacity: 0.35, blurRadius: 14),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    body,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.boneDim,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
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
    return AuraPanel(
      hue: AuraHue.magenta,
      padding: EdgeInsets.zero,
      radius: size / 2,
      showGrain: true,
      child: SizedBox(
        height: size,
        width: size,
        child: Center(
          child: CustomReminderIcon(icon: icon, color: color, size: iconSize),
        ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: 54,
            width: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.line),
            ),
            child: Center(
              child: CustomReminderIcon(
                icon: icon,
                color: AppColors.bone,
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.bone,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  body,
                  style: const TextStyle(
                    color: AppColors.boneDim,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: ready ? 0.12 : 0.07),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.line),
                ),
                child: Center(
                  child: CustomReminderIcon(
                    icon: icon,
                    color: ready ? AppColors.bone : AppColors.boneDim,
                    size: 22,
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
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppColors.bone,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(body, style: _subtle(context, small: true)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (ready)
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_rounded, color: AppColors.bone, size: 15),
                    SizedBox(width: 4),
                    Text(
                      'Allowed',
                      style: TextStyle(
                        color: AppColors.bone,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                )
              else
                TextButton(
                  onPressed: onTap,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.bone,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 36),
                  ),
                  child: Text(actionLabel),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
