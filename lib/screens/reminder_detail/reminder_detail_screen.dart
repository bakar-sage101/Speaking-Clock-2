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
      appBar: AppBar(
        title: const Text('Reminder details'),
        actions: [
          IconButton(
            tooltip: 'Edit reminder',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Delete reminder',
            onPressed: () => _confirmDelete(context),
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: AppColors.ashGrey.withValues(alpha: 0.16),
                ),
              ),
              child: ReminderIcon(type: reminder.type, large: true),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            reminder.title,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            reminder.time,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 28),
          _DetailCard(label: 'Schedule', value: reminder.detail),
          const SizedBox(height: 10),
          _DetailCard(
            label: 'Delivery',
            value: _deliveryLabel(reminder.deliveryMode),
          ),
          const SizedBox(height: 10),
          _DetailCard(label: 'Tone', value: _toneLabel(reminder.tone)),
          if (reminder.isSpeakingAlarm) ...[
            const SizedBox(height: 10),
            _DetailCard(
              label: 'Spoken message',
              value: reminder.spokenMessage.isEmpty
                  ? 'It is time for ${reminder.title}'
                  : reminder.spokenMessage,
            ),
          ],
          const SizedBox(height: 10),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              decoration: BoxDecoration(
                gradient: AppColors.softCardGradient,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.line.withValues(alpha: 0.72),
                ),
              ),
              child: SwitchListTile.adaptive(
                value: reminder.enabled,
                onChanged: onToggleEnabled,
                secondary: Icon(
                  reminder.enabled
                      ? Icons.play_circle_outline_rounded
                      : Icons.pause_circle_outline_rounded,
                  color: AppColors.darkWine,
                ),
                title: const Text(
                  'Enabled',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  reminder.enabled
                      ? 'This reminder can fire'
                      : 'Paused reminders stay saved but do not fire',
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
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
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Snoozed for 10 minutes.')),
              ),
              icon: const Icon(Icons.snooze_rounded),
              label: const Text('Snooze 10 min'),
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

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.softCardGradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line.withValues(alpha: 0.72)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: _sectionLabel(context)),
          const SizedBox(height: 6),
          Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
