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
                  Icons.auto_awesome_rounded,
                  color: AppColors.darkWine,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Routines',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Quick-start reminders for a healthier workday.',
                      style: _subtle(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Text('Quick start', style: _sectionLabel(context)),
        const SizedBox(height: 10),
        ..._routineTemplates.map(
          (template) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: RoutinePreset(
              template: template,
              onTap: () => onUseTemplate(template.draft),
            ),
          ),
        ),
        const SizedBox(height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Your routines', style: _sectionLabel(context)),
            _TinyBadge(label: '${routines.length}', color: AppColors.sage),
          ],
        ),
        const SizedBox(height: 10),
        if (routines.isEmpty)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: AppColors.softCardGradient,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.line.withValues(alpha: 0.75)),
            ),
            child: Text(
              'No routines yet. Pick a quick-start template above or create your own.',
              style: _subtle(context),
            ),
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
        const SizedBox(height: 10),
        FilledButton.tonalIcon(
          onPressed: onAdd,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Create a custom routine'),
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

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final ReminderDraft draft;
}

const _routineTemplates = [
  RoutineTemplate(
    icon: Icons.water_drop_outlined,
    title: 'Drink water',
    subtitle: 'A gentle hydration nudge during work.',
    color: AppColors.blue,
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
    icon: Icons.self_improvement_outlined,
    title: 'Stand and stretch',
    subtitle: 'Step away from the desk for a quick reset.',
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
    icon: Icons.visibility_outlined,
    title: 'Eye break',
    subtitle: 'Look away from the screen and relax your eyes.',
    color: AppColors.blue,
    draft: ReminderDraft(
      title: 'Eye break',
      type: ReminderType.breakTime,
      deliveryMode: DeliveryMode.gentle,
      repeatRule: 'Every 30 min',
      tone: ToneOption.softChime,
      snoozeMinutes: 5,
    ),
  ),
  RoutineTemplate(
    icon: Icons.medication_outlined,
    title: 'Medication',
    subtitle: 'A stronger reminder for something important.',
    color: AppColors.amber,
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
    icon: Icons.videocam_outlined,
    title: 'Meeting prep',
    subtitle: 'A spoken nudge before you need to join.',
    color: AppColors.amber,
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
    icon: Icons.coffee_outlined,
    title: 'Deep work break',
    subtitle: 'A reliable interruption after a focused sprint.',
    color: AppColors.sage,
    draft: ReminderDraft(
      title: 'Deep work break',
      type: ReminderType.breakTime,
      deliveryMode: DeliveryMode.alarm,
      repeatRule: 'Every 120 min',
      tone: ToneOption.digitalBeep,
      snoozeMinutes: 10,
    ),
  ),
];

class RoutinePreset extends StatelessWidget {
  const RoutinePreset({super.key, required this.template, required this.onTap});

  final RoutineTemplate template;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppColors.softCardGradient,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.line.withValues(alpha: 0.72)),
            boxShadow: [
              BoxShadow(
                color: AppColors.darkWine.withValues(alpha: 0.028),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  color: template.color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(template.icon, color: template.color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      template.subtitle,
                      style: _subtle(context, small: true),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _TinyBadge(
                          label: _deliveryShortLabel(
                            template.draft.deliveryMode,
                          ),
                          color: _deliveryAccent(template.draft.deliveryMode),
                          icon: _deliveryIcon(template.draft.deliveryMode),
                        ),
                        _TinyBadge(
                          label: template.draft.repeatRule,
                          color: AppColors.sage,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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
