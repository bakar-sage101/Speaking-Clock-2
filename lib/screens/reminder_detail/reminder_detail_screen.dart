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
    return AuraPanel(
      hue: _auraForDelivery(reminder.deliveryMode),
      radius: 32,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  reminder.triggerAtMillis == null
                      ? 'NEXT REMINDER'
                      : 'NEXT • ${_friendlyDate(DateTime.fromMillisecondsSinceEpoch(reminder.triggerAtMillis!)).toUpperCase()}',
                  style: TextStyle(
                    color: AppColors.linen.withValues(alpha: 0.72),
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 3,
                    shadows: _softTextShadow(opacity: 0.24),
                  ),
                ),
              ),
              Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  color: AppColors.linen.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.linen.withValues(alpha: 0.14),
                  ),
                ),
                child: Center(
                  child: ReminderIcon(type: reminder.type, large: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            reminder.time,
            textAlign: TextAlign.left,
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              color: AppColors.linen,
              fontWeight: FontWeight.w900,
              letterSpacing: -2.4,
              shadows: _softTextShadow(opacity: 0.32, blurRadius: 14),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.linen.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: AppColors.linen.withValues(alpha: 0.16),
              ),
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
                  _deliveryLabel(reminder.deliveryMode).toUpperCase(),
                  style: TextStyle(
                    color: AppColors.linen,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 1.4,
                    shadows: _softTextShadow(opacity: 0.24),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            reminder.title,
            textAlign: TextAlign.left,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppColors.linen,
              fontWeight: FontWeight.w900,
              shadows: _softTextShadow(opacity: 0.3),
            ),
          ),
          const SizedBox(height: 22),
          GlassPanel(
            radius: 22,
            opacity: 0.065,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reminder.enabled ? 'Enabled' : 'Paused',
                        style: const TextStyle(
                          color: AppColors.bone,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        reminder.enabled
                            ? "I'll be there."
                            : 'This will not fire.',
                        style: _subtle(context, small: true),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: reminder.enabled,
                  onChanged: onToggleEnabled,
                  activeThumbColor: AppColors.bone,
                  activeTrackColor: AppColors.boneDim,
                ),
              ],
            ),
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
    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      radius: 18,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: AppColors.boneDim, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: const TextStyle(
                color: AppColors.boneDim,
                fontWeight: FontWeight.w900,
                fontSize: 11,
                letterSpacing: 2.4,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Flexible(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.bone,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
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
              foregroundColor: AppColors.ink,
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
              foregroundColor: AppColors.destructive,
              side: BorderSide(
                color: AppColors.destructive.withValues(alpha: 0.52),
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
