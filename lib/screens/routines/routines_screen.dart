part of '../../main.dart';

class RoutinesScreen extends StatelessWidget {
  const RoutinesScreen({
    super.key,
    required this.onAdd,
    required this.onUseTemplate,
    required this.userTemplates,
    required this.onAddTemplate,
  });

  final VoidCallback onAdd;
  final ValueChanged<ReminderDraft> onUseTemplate;
  final List<ReminderDraft> userTemplates;
  final VoidCallback onAddTemplate;

  @override
  Widget build(BuildContext context) {
    final presets = _routineTemplates.take(3).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 130),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Routines', style: _serif(size: 30, color: AppColors.bone)),
                  const SizedBox(height: 4),
                  Text(
                    'Templates to start a reminder fast.',
                    style: TextStyle(color: AppColors.boneDim, fontSize: 13.5),
                  ),
                ],
              ),
            ),
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: AppColors.glass,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.line),
              ),
              child: Icon(Icons.insights_rounded, size: 18, color: AppColors.boneDim),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _RhythmHero(onStart: onAddTemplate),
        const SizedBox(height: 22),
        Text('Templates', style: _serif(size: 19, color: AppColors.bone)),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.32,
          children: [
            for (final t in presets)
              _TemplateGridCard(
                type: t.draft.type,
                title: t.title,
                subtitle: t.subtitle,
                color: _intensityColor(t.draft.deliveryMode),
                onTap: () => onUseTemplate(t.draft),
              ),
            for (final d in userTemplates)
              _TemplateGridCard(
                type: d.type,
                title: d.title,
                subtitle: d.repeatRule,
                color: _intensityColor(d.deliveryMode),
                onTap: () => onUseTemplate(d),
              ),
            _AddTemplateCard(onTap: onAddTemplate),
          ],
        ),
      ],
    );
  }
}

class _RhythmHero extends StatelessWidget {
  const _RhythmHero({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 192,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _RhythmArtPainter())),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Build a better\nrhythm',
                      style: _serif(size: 26, color: AppColors.bone, height: 1.05),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Small habits.\nBig impact.',
                      style: TextStyle(color: AppColors.boneDim, fontSize: 13, height: 1.3),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: onStart,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Create a template',
                        style: TextStyle(
                          color: AppColors.brassDim,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.brassDim),
                    ],
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

class _RhythmArtPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final sun = Offset(w * 0.72, h * 0.72);
    final sunR = h * 0.17;

    for (var i = 1; i <= 6; i++) {
      final r = sunR * (1 + i * 0.62);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = AppColors.gentle.withValues(alpha: 0.16 - i * 0.018);
      canvas.drawArc(Rect.fromCircle(center: sun, radius: r), math.pi, math.pi, false, paint);
    }

    final dotPaint = Paint()..color = AppColors.brass.withValues(alpha: 0.9);
    canvas.drawCircle(Offset(w * 0.86, h * 0.28), 2.4, dotPaint);
    canvas.drawCircle(
      Offset(w * 0.3, h * 0.42),
      1.8,
      Paint()..color = AppColors.brass.withValues(alpha: 0.55),
    );

    canvas.drawCircle(
      sun,
      sunR,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.2, -0.3),
          radius: 1.0,
          colors: [
            Color.lerp(AppColors.brass, Colors.white, 0.4)!,
            AppColors.brass,
            AppColors.brassDim,
          ],
        ).createShader(Rect.fromCircle(center: sun, radius: sunR)),
    );

    final hill1 = Path()
      ..moveTo(0, h * 0.74)
      ..cubicTo(w * 0.25, h * 0.66, w * 0.5, h * 0.82, w * 0.78, h * 0.72)
      ..cubicTo(w * 0.9, h * 0.68, w * 0.96, h * 0.74, w, h * 0.72)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(hill1, Paint()..color = Color.lerp(AppColors.gentle, AppColors.ink, 0.72)!);

    final hill2 = Path()
      ..moveTo(0, h * 0.86)
      ..cubicTo(w * 0.3, h * 0.8, w * 0.6, h * 0.94, w, h * 0.84)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(hill2, Paint()..color = Color.lerp(AppColors.gentle, AppColors.ink, 0.82)!);
  }

  @override
  bool shouldRepaint(covariant _RhythmArtPainter oldDelegate) => false;
}

class _TemplateGridCard extends StatelessWidget {
  const _TemplateGridCard({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final ReminderType type;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _fillFor(color),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_cardIcon(type), color: _onFill(color), size: 28),
                const Spacer(),
                Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.bone.withValues(alpha: 0.5)),
              ],
            ),
            const Spacer(),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ).copyWith(color: AppColors.bone),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _mono(size: 9.5, color: AppColors.bone.withValues(alpha: 0.6), spacing: 0.2),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddTemplateCard extends StatelessWidget {
  const _AddTemplateCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.brass.withValues(alpha: 0.45)),
          color: AppColors.brass.withValues(alpha: 0.05),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 38,
              width: 38,
              decoration: BoxDecoration(
                color: AppColors.brass.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add_rounded, color: AppColors.brass, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              'Add template',
              style: TextStyle(color: AppColors.brass, fontWeight: FontWeight.w700, fontSize: 14),
            ),
            const SizedBox(height: 2),
            Text(
              'Create your own',
              style: _mono(size: 9, color: AppColors.boneDim, spacing: 0.3),
            ),
          ],
        ),
      ),
    );
  }
}

class RoutineTemplate {
  const RoutineTemplate({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.draft,
  });

  final SpeakingClockIcon icon;
  final String title;
  final String subtitle;
  final Color color;
  final ReminderDraft draft;
}

final List<RoutineTemplate> _routineTemplates = [
  RoutineTemplate(
    icon: SpeakingClockIcon.droplet,
    title: 'Hydration',
    subtitle: 'Every 60 min',
    color: AppColors.sage,
    draft: ReminderDraft(
      title: 'Drink water',
      type: ReminderType.water,
      deliveryMode: DeliveryMode.gentle,
      repeatRule: 'Every 60 min',
      tone: ToneOption.calmWater,
      snoozeMinutes: 10,
    ),
  ),
  RoutineTemplate(
    icon: SpeakingClockIcon.stretch,
    title: 'Stand & Stretch',
    subtitle: 'Every 90 min',
    color: AppColors.sage,
    draft: ReminderDraft(
      title: 'Stand and stretch',
      type: ReminderType.breakTime,
      deliveryMode: DeliveryMode.gentle,
      repeatRule: 'Every 90 min',
      tone: ToneOption.softChime,
      snoozeMinutes: 10,
    ),
  ),
  RoutineTemplate(
    icon: SpeakingClockIcon.pill,
    title: 'Medication',
    subtitle: 'Daily',
    color: AppColors.sage,
    draft: ReminderDraft(
      title: 'Take medication',
      type: ReminderType.medication,
      deliveryMode: DeliveryMode.alarm,
      repeatRule: 'Every day',
      tone: ToneOption.classicAlarm,
      snoozeMinutes: 5,
    ),
  ),
];
