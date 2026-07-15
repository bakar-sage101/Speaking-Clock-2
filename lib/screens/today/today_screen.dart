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
    final warnings = _readinessWarnings(readiness);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 108),
      children: [
        _TodayHeader(readiness: readiness),
        if (warnings.isNotEmpty) ...[
          const SizedBox(height: 18),
          PermissionWarningCard(
            messages: warnings,
            onReview: onOpenReliability,
          ),
        ],
        const SizedBox(height: 28),
        Row(
          children: [
            Text('Next up', style: _sectionLabel(context)),
            const SizedBox(width: 8),
            if (next != null)
              _TinyBadge(
                label: next.enabled ? 'Active' : 'Paused',
                color: next.enabled ? AppColors.sage : AppColors.amber,
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (next == null)
          EmptyReminderCard(onAdd: onAdd)
        else
          NextReminderCard(reminder: next, onOpen: () => onOpenReminder(next)),
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Later today', style: Theme.of(context).textTheme.titleLarge),
            TextButton(onPressed: onAdd, child: const Text('Add')),
          ],
        ),
        const SizedBox(height: 4),
        ...reminders
            .skip(next == null ? 0 : 1)
            .map(
              (reminder) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ReminderRow(
                  reminder: reminder,
                  onTap: () => onOpenReminder(reminder),
                ),
              ),
            ),
        const SizedBox(height: 18),
        const ReliabilityNote(),
      ],
    );
  }
}

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
                _greeting(),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 3),
              Text(_friendlyDate(DateTime.now()), style: _subtle(context)),
            ],
          ),
        ),
        ReadinessChip(readiness: readiness),
      ],
    );
  }
}

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
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.amberLight, AppColors.linen],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.amber),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Reliable Alarm needs attention',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                ...messages.map(
                  (message) => Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      '• $message',
                      style: const TextStyle(height: 1.3),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed: onReview,
                  icon: const Icon(Icons.shield_outlined),
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.signatureHeroGradient,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkWine.withValues(alpha: 0.16),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 58,
            width: 58,
            decoration: BoxDecoration(
              color: AppColors.linen.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: CustomReminderIcon(
                icon: SpeakingClockIcon.bell,
                color: AppColors.linen,
                size: 30,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Your day is quiet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColors.linen,
              shadows: _softTextShadow(opacity: 0.24),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Create a gentle nudge, a full-screen alarm, or a spoken reminder when something matters.',
            style: TextStyle(
              color: AppColors.linen.withValues(alpha: 0.78),
              height: 1.35,
              fontWeight: FontWeight.w700,
              shadows: _softTextShadow(opacity: 0.22),
            ),
          ),
          const SizedBox(height: 14),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TinyBadge(
                label: 'Drink water',
                color: AppColors.blue,
                icon: Icons.water_drop_outlined,
              ),
              _TinyBadge(
                label: 'Stretch',
                color: AppColors.sage,
                icon: Icons.self_improvement_outlined,
              ),
              _TinyBadge(
                label: 'Meeting prep',
                color: AppColors.amber,
                icon: Icons.videocam_outlined,
              ),
            ],
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
        color: ready ? AppColors.sageLight : AppColors.amberLight,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            ready ? Icons.check_circle_rounded : Icons.info_outline_rounded,
            size: 16,
            color: ready ? AppColors.sage : AppColors.amber,
          ),
          const SizedBox(width: 5),
          Text(
            unknown
                ? 'Checking'
                : ready
                ? 'Ready'
                : 'Needs setup',
            style: TextStyle(
              color: ready ? AppColors.sage : AppColors.amber,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _TinyBadge extends StatelessWidget {
  const _TinyBadge({required this.label, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class NextReminderCard extends StatelessWidget {
  const NextReminderCard({
    super.key,
    required this.reminder,
    required this.onOpen,
  });

  final Reminder reminder;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    const foreground = AppColors.linen;
    final quietForeground = AppColors.linen.withValues(alpha: 0.78);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(34),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(34),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
          decoration: BoxDecoration(
            gradient: AppColors.signatureHeroGradient,
            borderRadius: BorderRadius.circular(34),
            boxShadow: [
              BoxShadow(
                color: AppColors.darkWine.withValues(alpha: 0.16),
                blurRadius: 30,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ReminderIcon(type: reminder.type, large: true),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.linen.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _deliveryIcon(reminder.deliveryMode),
                          size: 14,
                          color: AppColors.linen,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _deliveryLabel(reminder.deliveryMode),
                          style: const TextStyle(
                            color: AppColors.linen,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ).copyWith(shadows: _softTextShadow(opacity: 0.22)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              Text(
                reminder.time,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: foreground,
                  letterSpacing: -1.2,
                  shadows: _softTextShadow(opacity: 0.3),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                reminder.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: foreground,
                  shadows: _softTextShadow(opacity: 0.28),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                [
                  _repeatRule(reminder),
                  _toneLabel(reminder.tone),
                  if (reminder.isSpeakingAlarm) 'Speaks message',
                ].join(' · '),
                style: TextStyle(
                  color: quietForeground,
                  fontWeight: FontWeight.w800,
                  height: 1.35,
                  shadows: _softTextShadow(opacity: 0.24),
                ),
              ),
              if (!reminder.enabled) ...[
                const SizedBox(height: 12),
                const _TinyBadge(
                  label: 'Paused',
                  color: AppColors.amber,
                  icon: Icons.pause_circle_outline_rounded,
                ),
              ],
              const SizedBox(height: 18),
              Row(
                children: [
                  const Icon(
                    Icons.tune_rounded,
                    color: AppColors.linen,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Open reminder',
                    style: TextStyle(
                      color: AppColors.linen,
                      fontWeight: FontWeight.w800,
                    ).copyWith(shadows: _softTextShadow(opacity: 0.24)),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.linen.withValues(alpha: 0.85),
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ReminderRow extends StatelessWidget {
  const ReminderRow({super.key, required this.reminder, this.onTap});

  final Reminder reminder;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = _deliveryAccent(reminder.deliveryMode);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 12),
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
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: reminder.enabled
                            ? null
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _TinyBadge(
                          label: _deliveryShortLabel(reminder.deliveryMode),
                          color: accent,
                          icon: _deliveryIcon(reminder.deliveryMode),
                        ),
                        _TinyBadge(
                          label: _repeatRule(reminder),
                          color: AppColors.sage,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    reminder.time,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  if (!reminder.enabled)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Icon(
                        Icons.pause_circle_outline_rounded,
                        size: 16,
                        color: AppColors.amber,
                      ),
                    )
                  else if (reminder.isAlarm)
                    Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Icon(
                        reminder.isSpeakingAlarm
                            ? Icons.record_voice_over_rounded
                            : Icons.alarm_rounded,
                        size: 15,
                        color: accent,
                      ),
                    ),
                ],
              ),
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
    final data = switch (type) {
      ReminderType.water => (SpeakingClockIcon.droplet, AppColors.blue),
      ReminderType.breakTime => (SpeakingClockIcon.stretch, AppColors.sage),
      ReminderType.meeting => (SpeakingClockIcon.calendar, AppColors.amber),
      ReminderType.medication => (SpeakingClockIcon.pill, AppColors.amber),
      ReminderType.custom => (SpeakingClockIcon.bell, AppColors.sage),
    };
    final size = large ? 50.0 : 42.0;
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: data.$2.withValues(alpha: .16),
        borderRadius: BorderRadius.circular(large ? 16 : 13),
      ),
      child: Center(
        child: CustomReminderIcon(
          icon: data.$1,
          color: data.$2,
          size: large ? 28 : 23,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_user_outlined, color: AppColors.sage),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Set up Reliable Alarm before using it for important reminders. We will check the required device permissions for you.',
              style: TextStyle(height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
