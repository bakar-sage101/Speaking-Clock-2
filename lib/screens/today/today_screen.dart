part of '../../main.dart';

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
    final rest = reminders.where((r) => r.id != next?.id).toList();
    final warnings = _readinessWarnings(readiness);
    return Stack(
      children: [
        ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 130),
      children: [
        _TodayHeader(readiness: readiness),
        if (warnings.isNotEmpty) ...[
          const SizedBox(height: 16),
          PermissionWarningCard(messages: warnings, onReview: onOpenReliability),
        ],
        const SizedBox(height: 8),
        TodayDial(reminders: reminders, onAdd: onAdd),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'TAP THE CLOCK TO ADD A REMINDER',
            style: _mono(size: 8.5, color: AppColors.boneDim, spacing: 1.6),
          ),
        ),
        const SizedBox(height: 18),
        if (next == null)
          EmptyReminderCard(onAdd: onAdd)
        else
          _FolderReminderCard(
            reminder: next,
            big: true,
            onTap: () => onOpenReminder(next),
          ),
        const SizedBox(height: 26),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('REST OF TODAY', style: _mono(size: 10, color: AppColors.wine)),
            Text(
              '${reminders.length} planned',
              style: _mono(size: 10, color: AppColors.wine, spacing: 0.4),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (final reminder in rest)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _FolderReminderCard(
              reminder: reminder,
              big: false,
              onTap: () => onOpenReminder(reminder),
            ),
          ),
        const SizedBox(height: 20),
        const ReliabilityNote(),
      ],
        ),
      ],
    );
  }
}

Color _intensityColor(DeliveryMode mode) => switch (mode) {
  DeliveryMode.gentle => AppColors.gentle,
  DeliveryMode.alarm => AppColors.alarm,
  DeliveryMode.speaking => AppColors.speaking,
};

class _TodayHeader extends StatelessWidget {
  const _TodayHeader({required this.readiness});

  final AlarmReadiness? readiness;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _friendlyDate(DateTime.now()).toUpperCase(),
                style: _mono(size: 10, color: AppColors.boneDim, spacing: 2.4),
              ),
              const SizedBox(height: 6),
              Text(
                _greeting(),
                style: _serif(size: 26, color: AppColors.bone, height: 1.02),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        ReadinessChip(readiness: readiness),
      ],
    );
  }
}

/// A live analog dial: real hands, brass indices, and reminder markers on the
/// rim coloured by intensity — the next one wears a brass ring.
class TodayDial extends StatefulWidget {
  const TodayDial({super.key, required this.reminders, this.onAdd});

  final List<Reminder> reminders;
  final VoidCallback? onAdd;

  @override
  State<TodayDial> createState() => _TodayDialState();
}

class _TodayDialState extends State<TodayDial> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nextId = widget.reminders.isEmpty ? null : widget.reminders.first.id;
    return Center(
      child: GestureDetector(
        onTap: widget.onAdd,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 236,
          height: 236,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _DialPainter(
                    reminders: widget.reminders,
                    nextId: nextId,
                    now: DateTime.now(),
                  ),
                ),
              ),
              if (widget.onAdd != null)
                Positioned(
                  right: 2,
                  bottom: 30,
                  child: Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: AppColors.brass,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.ink, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brass.withValues(alpha: 0.5),
                          blurRadius: 14,
                          spreadRadius: -2,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.add_rounded, color: AppColors.onBrass, size: 24),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  _DialPainter({
    required this.reminders,
    required this.nextId,
    required this.now,
  });

  final List<Reminder> reminders;
  final String? nextId;
  final DateTime now;

  Offset _polar(Offset c, double r, double deg) {
    final rad = deg * math.pi / 180;
    return Offset(c.dx + r * math.sin(rad), c.dy - r * math.cos(rad));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 3;

    // Face
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.15),
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

    // Ticks
    final minutePaint = Paint()
      ..color = AppColors.boneDim.withValues(alpha: 0.35)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    final hourPaint = Paint()
      ..color = AppColors.brass
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 60; i++) {
      final deg = i * 6.0;
      if (i % 5 == 0) {
        canvas.drawLine(
          _polar(center, r - 13, deg),
          _polar(center, r - 5, deg),
          hourPaint,
        );
      } else {
        canvas.drawLine(
          _polar(center, r - 8, deg),
          _polar(center, r - 5, deg),
          minutePaint,
        );
      }
    }

    // Numerals 12 / 3 / 6 / 9
    const numerals = [(0.0, '12'), (90.0, '3'), (180.0, '6'), (270.0, '9')];
    for (final (deg, label) in numerals) {
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: 15,
            color: AppColors.bone,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final p = _polar(center, r - 27, deg);
      tp.paint(canvas, p - Offset(tp.width / 2, tp.height / 2));
    }

    // Reminder markers on the rim
    for (final reminder in reminders) {
      final tod = _parseTimeLabel(reminder.time);
      if (tod == null) continue;
      final deg = (tod.hour % 12) * 30 + tod.minute * 0.5;
      final pos = _polar(center, r - 3, deg);
      final isNext = reminder.id == nextId;
      final color = reminder.enabled
          ? _intensityColor(reminder.deliveryMode)
          : AppColors.boneDim.withValues(alpha: 0.5);
      // separator behind marker
      canvas.drawCircle(pos, isNext ? 9 : 6.5, Paint()..color = AppColors.surface);
      if (isNext) {
        canvas.drawCircle(
          pos,
          9,
          Paint()
            ..color = AppColors.brass.withValues(alpha: 0.55)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
        canvas.drawCircle(pos, 7, Paint()..color = AppColors.brass);
        canvas.drawCircle(
          pos,
          8.5,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = AppColors.brass,
        );
      } else if (reminder.enabled) {
        canvas.drawCircle(pos, 5, Paint()..color = color);
      } else {
        canvas.drawCircle(
          pos,
          5,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4
            ..color = color,
        );
      }
    }

    // Hands
    final second = now.second + now.millisecond / 1000;
    final minute = now.minute + second / 60;
    final hour = now.hour % 12 + minute / 60;
    _hand(canvas, center, hour * 30, r * 0.52, 4.4, AppColors.bone);
    _hand(canvas, center, minute * 6, r * 0.74, 3, AppColors.bone);
    _hand(canvas, center, second * 6, r * 0.82, 1.4, AppColors.brass);

    canvas.drawCircle(center, 5.5, Paint()..color = AppColors.brass);
    canvas.drawCircle(center, 2, Paint()..color = AppColors.ink);
  }

  void _hand(Canvas canvas, Offset center, double deg, double len, double width, Color color) {
    canvas.drawLine(
      center,
      _polar(center, len, deg),
      Paint()
        ..color = color
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _DialPainter oldDelegate) => true;
}

class _FolderReminderCard extends StatelessWidget {
  const _FolderReminderCard({
    required this.reminder,
    required this.big,
    required this.onTap,
  });

  final Reminder reminder;
  final bool big;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final light = Theme.of(context).brightness == Brightness.light;
    final color = _intensityColor(reminder.deliveryMode);
    final enabled = reminder.enabled;
    final base = enabled ? color : AppColors.boneDim;
    final onCover = ThemeData.estimateBrightnessForColor(base) == Brightness.dark
        ? Colors.white
        : const Color(0xff211E1A);
    final (value, unit) = _countdownParts(reminder);
    final countdownText = value == 'now'
        ? 'NOW'
        : unit.isEmpty
        ? value.toUpperCase()
        : 'IN $value $unit'.toUpperCase();
    final timeParts = reminder.time.split(' ');
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(big ? 20 : 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(base, Colors.white, 0.22)!,
              base,
              Color.lerp(base, Colors.black, 0.12)!,
            ],
            stops: const [0.0, 0.55, 1.0],
          ),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: AppColors.line),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: light ? 0.08 : 0.30),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              _deliveryLabel(reminder.deliveryMode).toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _mono(size: 9, color: onCover, spacing: 1.4),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: onCover.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              countdownText,
                              style: _mono(size: 8, color: onCover, spacing: 0.8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      Text(
                        reminder.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _serif(size: big ? 23 : 20, color: onCover, height: 1.05),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_label(reminder.type)} · ${_repeatRule(reminder)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _mono(size: 10, color: onCover.withValues(alpha: 0.62), spacing: 0.2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  _cardIcon(reminder.type),
                  color: onCover,
                  size: big ? 34 : 30,
                ),
              ],
            ),
            SizedBox(height: big ? 18 : 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text.rich(
                  TextSpan(
                    text: timeParts.first,
                    style: TextStyle(
                      fontSize: big ? 40 : 34,
                      fontWeight: FontWeight.w700,
                      color: onCover,
                      letterSpacing: -1,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                    children: [
                      if (timeParts.length > 1)
                        TextSpan(
                          text: ' ${timeParts[1]}',
                          style: _mono(size: big ? 13 : 12, color: onCover.withValues(alpha: 0.62), spacing: 0.5),
                        ),
                    ],
                  ),
                ),
                const Spacer(),
                Icon(Icons.north_east_rounded, color: onCover, size: big ? 26 : 24),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

(String, String) _countdownParts(Reminder reminder) {
  if (!reminder.enabled) return ('paused', '');
  final ms = reminder.triggerAtMillis;
  if (ms == null) return ('—', '');
  final diff = DateTime.fromMillisecondsSinceEpoch(ms).difference(DateTime.now());
  if (diff.isNegative) return ('now', '');
  final mins = diff.inMinutes;
  if (mins < 60) return ('$mins', 'min');
  final hours = diff.inHours;
  if (hours < 24) return ('$hours', 'hr');
  return ('${diff.inDays}', 'day');
}


IconData _cardIcon(ReminderType type) => switch (type) {
  ReminderType.water => Icons.water_drop_rounded,
  ReminderType.breakTime => Icons.self_improvement_rounded,
  ReminderType.meeting => Icons.videocam_rounded,
  ReminderType.medication => Icons.medication_rounded,
  ReminderType.custom => Icons.notifications_active_rounded,
};

SpeakingClockIcon _iconForType(ReminderType type) => switch (type) {
  ReminderType.water => SpeakingClockIcon.droplet,
  ReminderType.breakTime => SpeakingClockIcon.stretch,
  ReminderType.meeting => SpeakingClockIcon.calendar,
  ReminderType.medication => SpeakingClockIcon.pill,
  ReminderType.custom => SpeakingClockIcon.bell,
};

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
        color: AppColors.alarm.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.alarm.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.alarm, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reliable Alarm needs attention',
                  style: _serif(size: 16, color: AppColors.bone),
                ),
                const SizedBox(height: 6),
                ...messages.map(
                  (message) => Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      '• $message',
                      style: TextStyle(height: 1.3, color: AppColors.boneDim, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed: onReview,
                  icon: const Icon(Icons.shield_outlined, size: 18),
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
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your day is quiet', style: _serif(size: 20, color: AppColors.bone)),
          const SizedBox(height: 6),
          Text(
            'Create a gentle nudge, a full-screen alarm, or a spoken reminder when something matters.',
            style: TextStyle(color: AppColors.boneDim, height: 1.4, fontSize: 13.5),
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.line),
        boxShadow: [_softLiftedShadow(opacity: 0.05, blurRadius: 10)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            ready ? Icons.check_circle_rounded : Icons.info_outline_rounded,
            size: 15,
            color: ready ? AppColors.gentle : AppColors.brass,
          ),
          const SizedBox(width: 5),
          Text(
            unknown
                ? 'Checking'
                : ready
                ? 'Ready'
                : 'Set up',
            style: _mono(
              size: 10,
              color: ready ? AppColors.bone : AppColors.boneDim,
              spacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _TinyBadge extends StatelessWidget {
  const _TinyBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 6,
            width: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: AppColors.bone,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact schedule row reused by Routines. Kept for API compatibility.
class ReminderRow extends StatelessWidget {
  const ReminderRow({super.key, required this.reminder, this.onTap});

  final Reminder reminder;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = _intensityColor(reminder.deliveryMode);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: reminder.enabled ? AppColors.bone : AppColors.boneDim,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_deliveryShortLabel(reminder.deliveryMode)} · ${_repeatRule(reminder)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _mono(size: 10, color: AppColors.boneDim, spacing: 0.3),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                reminder.time,
                style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.bone),
              ),
              const SizedBox(width: 8),
              Container(width: 3, height: 26, decoration: BoxDecoration(
                color: reminder.enabled ? color : AppColors.boneDim.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              )),
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
    final size = large ? 50.0 : 42.0;
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(large ? 16 : 13),
        border: Border.all(color: AppColors.line),
      ),
      child: Center(
        child: CustomReminderIcon(
          icon: _iconForType(type),
          color: AppColors.bone,
          size: large ? 28 : 22,
        ),
      ),
    );
  }
}

class ReliabilityNote extends StatelessWidget {
  const ReliabilityNote({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_user_outlined, color: AppColors.gentle, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Set up Reliable Alarm before using it for important reminders. We will check the required device permissions for you.',
              style: TextStyle(height: 1.35, fontSize: 13, color: AppColors.boneDim),
            ),
          ),
        ],
      ),
    );
  }
}
