part of '../../main.dart';

class ReminderDetailScreen extends StatelessWidget {
  const ReminderDetailScreen({
    super.key,
    required this.reminder,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleEnabled,
  });

  final Reminder reminder;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggleEnabled;

  @override
  Widget build(BuildContext context) {
    final timingActionLabel = reminder.deliveryMode == DeliveryMode.gentle
        ? 'Remind again in ${reminder.snoozeMinutes} min'
        : 'Snooze ${reminder.snoozeMinutes} min';
    final timingSnackbar = reminder.deliveryMode == DeliveryMode.gentle
        ? 'Reminder will nudge again in ${reminder.snoozeMinutes} minutes.'
        : 'Snoozed for ${reminder.snoozeMinutes} minutes.';
    return Scaffold(
      appBar: AppBar(title: const SizedBox.shrink()),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _ReminderDetailHero(
            reminder: reminder,
            onToggleEnabled: onToggleEnabled,
          ),
          const SizedBox(height: 22),
          _DetailListCard(
            children: [
              _DetailRow(
                icon: Icons.repeat_rounded,
                label: 'Repeat',
                value: _repeatRule(reminder),
              ),
              _DetailRow(
                icon: _deliveryIcon(reminder.deliveryMode),
                label: 'Delivery',
                value: _deliveryLabel(reminder.deliveryMode),
              ),
              _DetailRow(
                icon: _toneIcon(reminder.tone),
                label: 'Tone',
                value: _toneLabel(reminder.tone),
              ),
              _DetailRow(
                icon: Icons.snooze_rounded,
                label: reminder.deliveryMode == DeliveryMode.gentle
                    ? 'Remind again'
                    : 'Snooze',
                value: '${reminder.snoozeMinutes} minutes',
              ),
              _DetailRow(
                icon: Icons.schedule_rounded,
                label: 'Next reminder',
                value: reminder.triggerAtMillis == null
                    ? reminder.time
                    : '${_friendlyDate(DateTime.fromMillisecondsSinceEpoch(reminder.triggerAtMillis!))} at ${reminder.time}',
              ),
              if (reminder.isSpeakingAlarm)
                _DetailRow(
                  icon: Icons.record_voice_over_rounded,
                  label: 'Spoken message',
                  value: reminder.spokenMessage.isEmpty
                      ? 'It is time for ${reminder.title}'
                      : reminder.spokenMessage,
                ),
            ],
          ),
          const SizedBox(height: 28),
          _ReminderManagementActions(
            onEdit: onEdit,
            onDelete: () => _confirmDelete(context),
          ),
          const SizedBox(height: 18),
          if (reminder.type == ReminderType.meeting)
            FilledButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Meeting links will be connected with Google Calendar setup.',
                  ),
                ),
              ),
              icon: const Icon(Icons.videocam_rounded),
              label: const Text('Join meeting'),
            )
          else
            FilledButton.tonalIcon(
              onPressed: () => ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(timingSnackbar))),
              icon: const Icon(Icons.snooze_rounded),
              label: Text(timingActionLabel),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final delete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete reminder?'),
        content: Text('${reminder.title} will be removed from Speaking Clock.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (delete == true) onDelete();
  }
}

class _ReminderDetailHero extends StatelessWidget {
  const _ReminderDetailHero({
    required this.reminder,
    required this.onToggleEnabled,
  });

  final Reminder reminder;
  final ValueChanged<bool> onToggleEnabled;

  @override
  Widget build(BuildContext context) {
    return SoftPanel(
      radius: 32,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      gradient: AppColors.signatureHeroGradient,
      borderColor: Colors.transparent,
      shadowOpacity: 0.12,
      child: Column(
        children: [
          Container(
            height: 78,
            width: 78,
            decoration: BoxDecoration(
              color: AppColors.linen.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(26),
            ),
            child: Center(
              child: ReminderIcon(type: reminder.type, large: true),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            reminder.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.linen,
              fontWeight: FontWeight.w900,
              shadows: _softTextShadow(opacity: 0.3),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            reminder.time,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: AppColors.linen,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
              shadows: _softTextShadow(opacity: 0.3),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
                      color: AppColors.linen,
                      size: 15,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _deliveryLabel(reminder.deliveryMode),
                      style: TextStyle(
                        color: AppColors.linen,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        shadows: _softTextShadow(opacity: 0.24),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.only(left: 12),
                decoration: BoxDecoration(
                  color: AppColors.linen.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      reminder.enabled ? 'Enabled' : 'Paused',
                      style: TextStyle(
                        color: AppColors.linen,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        shadows: _softTextShadow(opacity: 0.24),
                      ),
                    ),
                    Transform.scale(
                      scale: 0.78,
                      child: Switch.adaptive(
                        value: reminder.enabled,
                        onChanged: onToggleEnabled,
                        activeThumbColor: AppColors.linen,
                        activeTrackColor: AppColors.ashGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailListCard extends StatelessWidget {
  const _DetailListCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: AppColors.softCardGradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line.withValues(alpha: 0.72)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              Divider(color: AppColors.line.withValues(alpha: 0.55), height: 1),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Icon(icon, color: AppColors.sage, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(value, style: _subtle(context, small: true)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderManagementActions extends StatelessWidget {
  const _ReminderManagementActions({
    required this.onEdit,
    required this.onDelete,
  });

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: FilledButton.icon(
            onPressed: onEdit,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(58),
              backgroundColor: AppColors.darkWine,
              foregroundColor: AppColors.linen,
              textStyle: const TextStyle(fontWeight: FontWeight.w900),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            icon: const Icon(Icons.edit_rounded),
            label: const Text('Edit'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: OutlinedButton.icon(
            onPressed: onDelete,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(58),
              foregroundColor: AppColors.darkWine,
              side: BorderSide(
                color: AppColors.darkWine.withValues(alpha: 0.42),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w900),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Delete'),
          ),
        ),
      ],
    );
  }
}
