part of '../../main.dart';

class RoutinesScreen extends StatelessWidget {
  const RoutinesScreen({
    super.key,
    required this.reminders,
    required this.onAdd,
    required this.onUseTemplate,
    required this.onOpenReminder,
  });

  final List<Reminder> reminders;
  final VoidCallback onAdd;
  final ValueChanged<ReminderDraft> onUseTemplate;
  final ValueChanged<Reminder> onOpenReminder;

  @override
  Widget build(BuildContext context) {
    final routines = reminders
        .where((item) => item.type != ReminderType.meeting)
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 108),
      children: [
        Text(
          'Routines',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppColors.bone,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 4),
        Text('Use a template to get started.', style: _subtle(context)),
        const SizedBox(height: 22),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.02,
          children: [
            for (final template in _routineTemplates.take(4))
              RoutinePreset(
                template: template,
                onTap: () => onUseTemplate(template.draft),
              ),
          ],
        ),
        const SizedBox(height: 12),
        RoutinePreset(
          template: _routineTemplates[4],
          wide: true,
          onTap: () => onUseTemplate(_routineTemplates[4].draft),
        ),
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Your routines', style: _sectionLabel(context)),
            _TinyBadge(label: '${routines.length}', color: AppColors.sage),
          ],
        ),
        const SizedBox(height: 10),
        if (routines.isEmpty)
          Text(
            'No routines yet. Pick a template above or create your own.',
            style: _subtle(context),
          )
        else
          ...routines.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ReminderRow(
                reminder: item,
                onTap: () => onOpenReminder(item),
              ),
            ),
          ),
      ],
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

const _routineTemplates = [
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
  RoutineTemplate(
    icon: SpeakingClockIcon.target,
    title: 'Focus Session',
    subtitle: '25 min focus',
    color: AppColors.darkWine,
    draft: ReminderDraft(
      title: 'Focus Session',
      type: ReminderType.breakTime,
      deliveryMode: DeliveryMode.gentle,
      repeatRule: 'Every 25 min',
      tone: ToneOption.softChime,
      snoozeMinutes: 5,
    ),
  ),
  RoutineTemplate(
    icon: SpeakingClockIcon.calendar,
    title: 'Meeting Prep',
    subtitle: '10 min before meeting',
    color: AppColors.sage,
    draft: ReminderDraft(
      title: 'Meeting prep',
      type: ReminderType.meeting,
      deliveryMode: DeliveryMode.speaking,
      repeatRule: 'Once',
      tone: ToneOption.morningBell,
      spokenMessage: 'Your meeting starts soon.',
      snoozeMinutes: 5,
    ),
  ),
  RoutineTemplate(
    icon: SpeakingClockIcon.target,
    title: 'Eye break',
    subtitle: 'Every 30 min',
    color: AppColors.sage,
    draft: ReminderDraft(
      title: 'Eye break',
      type: ReminderType.breakTime,
      deliveryMode: DeliveryMode.gentle,
      repeatRule: 'Every 30 min',
      tone: ToneOption.softChime,
      snoozeMinutes: 5,
    ),
  ),
];

class RoutinePreset extends StatelessWidget {
  const RoutinePreset({
    super.key,
    required this.template,
    required this.onTap,
    this.wide = false,
  });

  final RoutineTemplate template;
  final VoidCallback onTap;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final hue = switch (template.draft.deliveryMode) {
      DeliveryMode.gentle => AuraHue.lime,
      DeliveryMode.alarm => AuraHue.coral,
      DeliveryMode.speaking => AuraHue.magenta,
    };
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: AuraPanel(
          hue: hue,
          padding: const EdgeInsets.all(14),
          radius: 22,
          child: wide
              ? Row(
                  children: [
                    _RoutineIcon(template: template),
                    const SizedBox(width: 14),
                    Expanded(child: _RoutineText(template: template)),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _RoutineIcon(template: template),
                    const Spacer(),
                    _RoutineText(template: template),
                  ],
                ),
        ),
      ),
    );
  }
}

class _RoutineIcon extends StatelessWidget {
  const _RoutineIcon({required this.template});

  final RoutineTemplate template;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      width: 48,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Center(
        child: CustomReminderIcon(
          icon: template.icon,
          color: AppColors.bone,
          size: 26,
        ),
      ),
    );
  }
}

class _RoutineText extends StatelessWidget {
  const _RoutineText({required this.template});

  final RoutineTemplate template;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          template.title,
          style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.bone),
        ),
        const SizedBox(height: 4),
        Text(
          template.subtitle,
          style: TextStyle(
            color: AppColors.boneDim,
            fontWeight: FontWeight.w900,
            fontSize: 13,
            height: 1.25,
          ),
        ),
      ],
    );
  }
}
