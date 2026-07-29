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
        Positioned.fill(child: ColoredBox(color: AppColors.ink)),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: center,
                radius: 0.9,
                colors: [
                  dominant.withValues(alpha: 0.16),
                  dominant.withValues(alpha: 0.05),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.4, 0.8],
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
                colors: [edge.withValues(alpha: 0.08), Colors.transparent],
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
                  ? AppColors.brass
                  : AppColors.bone.withValues(alpha: 0.18),
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
      top: Text(
        'SPEAKING CLOCK',
        style: _mono(size: 10, color: AppColors.boneDim, spacing: 4),
      ),
      title: 'A clock that speaks up when you go too deep.',
      body: 'Water, breaks, medication, meetings — reached gently, or impossible to ignore. You choose, per reminder.',
      art: const _DialMark(size: 150),
      primaryLabel: 'Begin setup',
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
      content: Column(
        children: [
          _IntensityTile(
            icon: Icons.notifications_none_rounded,
            title: 'Gentle reminder',
            body: 'A soft notification to nudge you.',
            color: AppColors.gentle,
          ),
          SizedBox(height: 12),
          _IntensityTile(
            icon: Icons.alarm_rounded,
            title: 'Alarm reminder',
            body: 'A reliable alarm to get your attention.',
            color: AppColors.alarm,
          ),
          SizedBox(height: 12),
          _IntensityTile(
            icon: Icons.record_voice_over_rounded,
            title: 'Speaking reminder',
            body: 'An alarm that speaks a message aloud.',
            color: AppColors.speaking,
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
      art: const _DialMark(size: 128),
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
                    style: _serif(size: 32, color: AppColors.bone, height: 1.05),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    body,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.boneDim,
                      height: 1.45,
                      fontSize: 14.5,
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

class _DialMark extends StatelessWidget {
  const _DialMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _DialMarkPainter()),
    );
  }
}

class _DialMarkPainter extends CustomPainter {
  Offset _polar(Offset c, double r, double deg) {
    final rad = deg * math.pi / 180;
    return Offset(c.dx + r * math.sin(rad), c.dy - r * math.cos(rad));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 2;
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..shader = RadialGradient(
          center: Alignment(0, -0.2),
          radius: 0.95,
          colors: [AppColors.surfaceRaised, AppColors.surface],
        ).createShader(Rect.fromCircle(center: center, radius: r)),
    );
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = AppColors.line2,
    );
    final hourTick = Paint()
      ..color = AppColors.brass
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 12; i++) {
      final deg = i * 30.0;
      canvas.drawLine(_polar(center, r - 11, deg), _polar(center, r - 5, deg), hourTick);
    }
    _hand(canvas, center, 300, r * 0.48, 3.4, AppColors.bone);
    _hand(canvas, center, 66, r * 0.70, 2.4, AppColors.brass);
    canvas.drawCircle(center, 4.5, Paint()..color = AppColors.brass);
    canvas.drawCircle(center, 1.6, Paint()..color = AppColors.ink);
  }

  void _hand(Canvas canvas, Offset center, double deg, double len, double w, Color col) {
    canvas.drawLine(
      center,
      _polar(center, len, deg),
      Paint()
        ..color = col
        ..strokeWidth = w
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _DialMarkPainter oldDelegate) => false;
}

class _IntensityTile extends StatelessWidget {
  const _IntensityTile({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.bone,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: TextStyle(
                    color: AppColors.boneDim,
                    fontSize: 12.5,
                    height: 1.3,
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
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  color: ready
                      ? AppColors.gentle.withValues(alpha: 0.15)
                      : AppColors.surfaceRaised,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: CustomReminderIcon(
                    icon: icon,
                    color: ready ? AppColors.gentle : AppColors.boneDim,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.bone,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(body, style: TextStyle(color: AppColors.boneDim, fontSize: 11.5)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (ready)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: AppColors.gentle.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    'On',
                    style: _mono(size: 10, color: AppColors.gentle, spacing: 1),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.brass,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    actionLabel,
                    style: _mono(size: 10, color: const Color(0xff1A1205), spacing: 0.8),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
