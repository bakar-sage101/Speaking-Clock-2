part of '../main.dart';

TextStyle _sectionLabel(BuildContext context) =>
    Theme.of(context).textTheme.labelMedium!.copyWith(
      letterSpacing: 1.2,
      fontWeight: FontWeight.w800,
      color: AppColors.wine,
    );
TextStyle _subtle(BuildContext context, {bool small = false}) =>
    (small
            ? Theme.of(context).textTheme.bodySmall
            : Theme.of(context).textTheme.bodyMedium)!
        .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);

/// Humanist serif for anything the clock "says" — greetings, titles, spoken
/// lines. On Android this resolves to Noto Serif.
TextStyle _serif({
  double size = 24,
  Color? color,
  FontWeight weight = FontWeight.w500,
  double height = 1.05,
  double letterSpacing = -0.2,
}) => TextStyle(
  fontFamily: 'serif',
  fontSize: size,
  color: color,
  fontWeight: weight,
  height: height,
  letterSpacing: letterSpacing,
);

/// Monospace instrument face for eyebrows, units and timestamps. On Android
/// this resolves to Roboto Mono.
TextStyle _mono({
  double size = 10,
  Color? color,
  double spacing = 2.2,
  FontWeight weight = FontWeight.w600,
}) => TextStyle(
  fontFamily: 'monospace',
  fontSize: size,
  color: color,
  letterSpacing: spacing,
  fontWeight: weight,
);

/// A solid card fill derived from an intensity colour — a soft pastel in light
/// mode, a subtly-tinted dark surface in dark mode.
Color _fillFor(Color intensity) => AppColors.brightness == Brightness.light
    ? Color.lerp(intensity, Colors.white, 0.48)!
    : Color.lerp(intensity, AppColors.surface, 0.82)!;

/// Deepened, high-contrast version of an intensity colour for text/icons that
/// sit on a [_fillFor] pastel header in light mode.
Color _onFill(Color intensity) => AppColors.brightness == Brightness.light
    ? Color.lerp(intensity, Colors.black, 0.34)!
    : intensity;

List<Shadow> _softTextShadow({double opacity = 0.28, double blurRadius = 9}) {
  return [
    Shadow(
      color: Colors.black.withValues(alpha: opacity),
      blurRadius: blurRadius,
      offset: const Offset(0, 1.2),
    ),
  ];
}

BoxShadow _softLiftedShadow({double opacity = 0.08, double blurRadius = 22}) {
  return BoxShadow(
    color: Colors.black.withValues(alpha: opacity),
    blurRadius: blurRadius,
    offset: const Offset(0, 12),
  );
}

enum AuraHue { magenta, blue, coral, lime }

class AuraSpec {
  const AuraSpec({
    required this.dominant,
    required this.edge,
    required this.center,
    required this.edgeCenter,
    this.dominantOpacity = 0.85,
    this.edgeOpacity = 0.26,
  });

  final Color dominant;
  final Color edge;
  final Alignment center;
  final Alignment edgeCenter;
  final double dominantOpacity;
  final double edgeOpacity;
}

AuraSpec _auraSpec(AuraHue hue) => switch (hue) {
  AuraHue.magenta => AuraSpec(
    dominant: AppColors.auraMagenta,
    edge: AppColors.auraBlue,
    center: Alignment(-0.1, 0.15),
    edgeCenter: Alignment(0.95, -0.9),
    dominantOpacity: 0.85,
    edgeOpacity: 0.28,
  ),
  AuraHue.blue => AuraSpec(
    dominant: AppColors.auraBlue,
    edge: AppColors.auraMagenta,
    center: Alignment(0.0, 0.0),
    edgeCenter: Alignment(0.9, -0.85),
    dominantOpacity: 0.85,
    edgeOpacity: 0.25,
  ),
  AuraHue.coral => AuraSpec(
    dominant: AppColors.auraCoral,
    edge: AppColors.auraLime,
    center: Alignment(0.0, 0.0),
    edgeCenter: Alignment(-0.95, 0.95),
    dominantOpacity: 0.80,
    edgeOpacity: 0.22,
  ),
  AuraHue.lime => AuraSpec(
    dominant: AppColors.auraLime,
    edge: AppColors.auraBlue,
    center: Alignment(-0.2, 0.0),
    edgeCenter: Alignment(0.95, 0.95),
    dominantOpacity: 0.70,
    edgeOpacity: 0.24,
  ),
};


class SoftPanel extends StatelessWidget {
  const SoftPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 22,
    this.gradient,
    this.borderColor,
    this.shadowOpacity = 0.025,
    this.backgroundColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Gradient? gradient;
  final Color? borderColor;
  final double shadowOpacity;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.glass,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: borderColor ?? AppColors.line.withValues(alpha: 0.62),
        ),
        boxShadow: [_softLiftedShadow(opacity: shadowOpacity, blurRadius: 14)],
      ),
      child: child,
    );
  }
}

class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 22,
    this.opacity = 0.04,
    this.gradient,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double opacity;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: opacity),
            gradient: gradient,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: AppColors.line),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.24),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class AuraPanel extends StatelessWidget {
  const AuraPanel({
    super.key,
    required this.child,
    this.hue = AuraHue.magenta,
    this.padding = const EdgeInsets.all(20),
    this.radius = 28,
    this.showGrain = true,
  });

  final Widget child;
  final AuraHue hue;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool showGrain;

  @override
  Widget build(BuildContext context) {
    final spec = _auraSpec(hue);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(radius),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: spec.center,
                  radius: 1.0,
                  colors: [
                    spec.dominant.withValues(alpha: 0.16),
                    spec.dominant.withValues(alpha: 0.045),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.42, 0.85],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: spec.edgeCenter,
                  radius: 1.2,
                  colors: [
                    spec.edge.withValues(alpha: 0.07),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5],
                ),
              ),
            ),
          ),
          if (showGrain)
            const Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _NoisePainter()),
              ),
            ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(color: AppColors.line),
              ),
            ),
          ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}

class _NoisePainter extends CustomPainter {
  const _NoisePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.045)
      ..strokeWidth = 1;
    var seed = 17;
    for (var i = 0; i < 900; i++) {
      seed = (seed * 1103515245 + 12345) & 0x7fffffff;
      final x = (seed % 10000) / 10000 * size.width;
      seed = (seed * 1103515245 + 12345) & 0x7fffffff;
      final y = (seed % 10000) / 10000 * size.height;
      canvas.drawPoints(PointMode.points, [Offset(x, y)], paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

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
