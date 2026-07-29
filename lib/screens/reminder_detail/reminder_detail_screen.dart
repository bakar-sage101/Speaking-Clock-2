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
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              height: 4,
              width: 36,
              decoration: BoxDecoration(
                color: AppColors.line2,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
                child: Column(
                  children: [
                  _DetailHero(reminder: reminder, onToggleEnabled: onToggleEnabled),
                  const SizedBox(height: 16),
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
                  const SizedBox(height: 20),
                  _ReminderManagementActions(
                    onEdit: onEdit,
                    onDelete: () => _confirmDelete(context),
                    color: _intensityColor(reminder.deliveryMode),
                  ),
                ],
              ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final delete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceRaised,
        title: Text('Delete reminder?', style: _serif(size: 20, color: AppColors.bone)),
        content: Text(
          '${reminder.title} will be removed from Speaking Clock.',
          style: TextStyle(color: AppColors.boneDim),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.destructive,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (delete == true) onDelete();
  }
}

class _DetailHero extends StatefulWidget {
  const _DetailHero({required this.reminder, required this.onToggleEnabled});

  final Reminder reminder;
  final ValueChanged<bool> onToggleEnabled;

  @override
  State<_DetailHero> createState() => _DetailHeroState();
}

class _DetailHeroState extends State<_DetailHero> {
  late bool enabled = widget.reminder.enabled;

  @override
  Widget build(BuildContext context) {
    final reminder = widget.reminder;
    final mode = reminder.deliveryMode;
    final light = Theme.of(context).brightness == Brightness.light;
    final base = enabled ? _intensityColor(mode) : AppColors.boneDim;
    final onCover = ThemeData.estimateBrightnessForColor(base) == Brightness.dark
        ? Colors.white
        : const Color(0xff211E1A);
    final onWhite = onCover == Colors.white;
    final stripBg = onWhite
        ? Colors.black.withValues(alpha: 0.20)
        : Colors.black.withValues(alpha: 0.07);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: light ? 0.10 : 0.35),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
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
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.85, -0.85),
                    radius: 0.9,
                    colors: [Colors.white.withValues(alpha: 0.18), Colors.transparent],
                    stops: const [0.0, 0.6],
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _deliveryLabel(mode).toUpperCase(),
                      style: _mono(size: 10, color: onCover, spacing: 1.6),
                    ),
                    const Spacer(),
                    Icon(_cardIcon(reminder.type), color: onCover, size: 32),
                  ],
                ),
                const SizedBox(height: 22),
                Text(
                  reminder.time,
                  style: TextStyle(
                    color: onCover,
                    fontSize: 54,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1.5,
                    height: 1.0,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  reminder.title,
                  style: _serif(size: 24, color: onCover, height: 1.1),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
                  decoration: BoxDecoration(
                    color: stripBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              enabled ? 'Enabled' : 'Paused',
                              style: TextStyle(
                                color: onCover,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              enabled ? "I'll be there." : 'This will not fire.',
                              style: TextStyle(
                                color: onCover.withValues(alpha: 0.72),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: enabled,
                        onChanged: (value) {
                          setState(() => enabled = value);
                          widget.onToggleEnabled(value);
                        },
                        activeThumbColor: onCover,
                        activeTrackColor: onCover.withValues(alpha: 0.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              Divider(color: AppColors.line, height: 1, indent: 16, endIndent: 16),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.boneDim, size: 17),
          const SizedBox(width: 11),
          Text(label.toUpperCase(), style: _mono(size: 9.5, color: AppColors.boneDim, spacing: 1.4)),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: AppColors.bone,
                fontWeight: FontWeight.w600,
                height: 1.3,
                fontSize: 14,
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
    required this.color,
  });

  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onEdit,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(58),
              backgroundColor: color,
              foregroundColor: AppColors.ink,
              textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            icon: const Icon(Icons.edit_rounded, size: 20),
            label: const Text('Edit reminder'),
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: onDelete,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.destructive,
            minimumSize: const Size.fromHeight(44),
          ),
          icon: const Icon(Icons.delete_outline_rounded, size: 18),
          label: const Text(
            'Delete reminder',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
