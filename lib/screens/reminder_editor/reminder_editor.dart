part of '../../main.dart';

class _SchedulePreview extends StatelessWidget {
  const _SchedulePreview({required this.triggerAt, this.customRepeatMinutes});

  final DateTime triggerAt;
  final int? customRepeatMinutes;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final triggerDay = DateTime(triggerAt.year, triggerAt.month, triggerAt.day);
    final dayLabel = triggerDay == today ? 'Today' : 'Tomorrow';
    final isTomorrow = dayLabel == 'Tomorrow';
    final text = customRepeatMinutes == null
        ? 'Will fire $dayLabel at ${_formatTime12(TimeOfDay.fromDateTime(triggerAt))}'
        : 'First fire $dayLabel at ${_formatTime12(TimeOfDay.fromDateTime(triggerAt))}, then every $customRepeatMinutes min';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: isTomorrow
            ? const LinearGradient(
                colors: [AppColors.amberLight, AppColors.linen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : AppColors.softCardGradient,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isTomorrow
              ? AppColors.mutedWine.withValues(alpha: 0.18)
              : AppColors.ashGrey.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isTomorrow
                ? Icons.info_outline_rounded
                : Icons.check_circle_outline_rounded,
            size: 18,
            color: isTomorrow ? AppColors.mutedWine : AppColors.darkWine,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isTomorrow ? AppColors.mutedWine : AppColors.darkWine,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ReminderEditor extends StatefulWidget {
  const ReminderEditor({
    super.key,
    required this.initialType,
    this.reminder,
    this.draft,
  });

  final ReminderType initialType;
  final Reminder? reminder;
  final ReminderDraft? draft;

  @override
  State<ReminderEditor> createState() => _ReminderEditorState();
}

class _ReminderEditorState extends State<ReminderEditor> {
  final _controller = TextEditingController();
  final _spokenController = TextEditingController();
  final _customRepeatController = TextEditingController(text: '30');
  static const _repeatOptions = [
    'Once',
    'Every day',
    'Weekdays',
    'Custom minutes',
  ];
  late ReminderType _type;
  late DeliveryMode _deliveryMode;
  late ToneOption _tone;
  late TimeOfDay _time;
  var _frequency = 'Every day';
  var _snoozeMinutes = 10;

  String get _selectedRepeatRule {
    if (_frequency != 'Custom minutes') return _frequency;
    return 'Every $_customRepeatMinutes min';
  }

  int get _customRepeatMinutes {
    final minutes = int.tryParse(_customRepeatController.text.trim());
    return minutes == null ? 30 : minutes.clamp(1, 1440);
  }

  bool get _canSave => _controller.text.trim().isNotEmpty;

  String get _fallbackSpokenMessage {
    final title = _controller.text.trim();
    return 'It is time for ${title.isEmpty ? 'this reminder' : title}.';
  }

  DateTime get _selectedTriggerAt {
    return _triggerForTime(_time);
  }

  @override
  void initState() {
    super.initState();
    final reminder = widget.reminder;
    final draft = widget.draft;
    _type = reminder?.type ?? draft?.type ?? widget.initialType;
    _deliveryMode =
        reminder?.deliveryMode ?? draft?.deliveryMode ?? DeliveryMode.gentle;
    _tone = reminder?.tone ?? draft?.tone ?? ToneOption.softChime;
    _time = _defaultReminderTime();
    _snoozeMinutes = reminder?.snoozeMinutes ?? draft?.snoozeMinutes ?? 10;
    if (draft != null && reminder == null) {
      _controller.text = draft.title;
      _spokenController.text = draft.spokenMessage;
      _applyRepeatRule(draft.repeatRule);
    }
    if (reminder != null) {
      _controller.text = reminder.title;
      _spokenController.text = reminder.spokenMessage;
      _applyRepeatRule(reminder.detail.split(' · ').first);
      _time = _parseTimeLabel(reminder.time) ?? _time;
    }
  }

  void _applyRepeatRule(String repeatRule) {
    final customMinutes = _customRepeatMinutesFromRule(repeatRule);
    if (customMinutes != null) {
      _frequency = 'Custom minutes';
      _customRepeatController.text = '$customMinutes';
    } else {
      _frequency = _repeatOptions.contains(repeatRule)
          ? repeatRule
          : 'Every day';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _spokenController.dispose();
    _customRepeatController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked != null) setState(() => _time = picked);
  }

  void _save() {
    if (!_canSave) return;
    final title = _controller.text.trim();
    final now = DateTime.now();
    final triggerAt = _selectedTriggerAt;
    final reminder = widget.reminder;
    final spokenMessage = _spokenController.text.trim();
    final repeatRule = _selectedRepeatRule;
    Navigator.pop(
      context,
      Reminder(
        id: reminder?.id ?? '${now.microsecondsSinceEpoch}',
        title: title,
        time: _formatTime12(_time),
        detail: '$repeatRule · ${_deliveryLabel(_deliveryMode)}',
        type: _type,
        deliveryMode: _deliveryMode,
        spokenMessage: spokenMessage,
        tone: _tone,
        enabled: reminder?.enabled ?? true,
        snoozeMinutes: _snoozeMinutes,
        triggerAtMillis: triggerAt.millisecondsSinceEpoch,
        createdAtMillis:
            reminder?.createdAtMillis ?? now.millisecondsSinceEpoch,
        updatedAtMillis: now.millisecondsSinceEpoch,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.reminder != null;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(20, 12, 20, bottomInset + 18),
        decoration: BoxDecoration(
          color: AppColors.canvas,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  height: 4,
                  width: 42,
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 46,
                    width: 46,
                    decoration: BoxDecoration(
                      gradient: AppColors.heroGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.add_alarm_rounded,
                      color: AppColors.darkWine,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          editing ? 'Edit reminder' : 'Create reminder',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Choose how Speaking Clock should get your attention.',
                          style: _subtle(context),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _EditorCard(
                title: 'What should I remind you about?',
                icon: Icons.edit_note_rounded,
                child: TextField(
                  controller: _controller,
                  autofocus: !editing,
                  onChanged: (_) => setState(() {}),
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Drink water',
                    errorText: _controller.text.isEmpty
                        ? null
                        : _canSave
                        ? null
                        : 'Add a title before saving.',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _EditorCard(
                title: 'Reminder category',
                icon: Icons.category_outlined,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ReminderType.values
                      .map(
                        (type) => ChoiceChip(
                          label: Text(_label(type)),
                          selected: type == _type,
                          onSelected: (_) => setState(() => _type = type),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 14),
              _EditorCard(
                title: 'First reminder',
                icon: Icons.schedule_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OutlinedButton(
                      onPressed: _pickTime,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(72),
                        alignment: Alignment.centerLeft,
                        side: const BorderSide(color: AppColors.line),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        backgroundColor: AppColors.brightSnow,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: AppColors.softCardGradient,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.access_time_rounded,
                              color: AppColors.darkWine,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              _formatTime12(_time),
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.ink,
                                  ),
                            ),
                          ),
                          const Icon(Icons.keyboard_arrow_down_rounded),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    _SchedulePreview(
                      triggerAt: _selectedTriggerAt,
                      customRepeatMinutes: _frequency == 'Custom minutes'
                          ? _customRepeatMinutes
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _EditorCard(
                title: 'Repeat',
                icon: Icons.repeat_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _repeatOptions
                          .map(
                            (option) => ChoiceChip(
                              label: Text(option),
                              selected: option == _frequency,
                              onSelected: (_) =>
                                  setState(() => _frequency = option),
                            ),
                          )
                          .toList(),
                    ),
                    if (_frequency == 'Custom minutes') ...[
                      const SizedBox(height: 14),
                      TextField(
                        controller: _customRepeatController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Repeat every',
                          suffixText: 'minutes',
                          helperText:
                              'First fire stays at ${_formatTime12(_time)}, then repeats every $_customRepeatMinutes min.',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _EditorCard(
                title: 'How should it remind you?',
                icon: Icons.notifications_active_outlined,
                child: Column(
                  children: DeliveryMode.values
                      .map(
                        (mode) => Padding(
                          padding: EdgeInsets.only(
                            bottom: mode == DeliveryMode.values.last ? 0 : 10,
                          ),
                          child: _DeliveryModeCard(
                            mode: mode,
                            selected: _deliveryMode == mode,
                            onTap: () => setState(() => _deliveryMode = mode),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              if (_deliveryMode == DeliveryMode.speaking) ...[
                const SizedBox(height: 14),
                _EditorCard(
                  title: 'What should it say?',
                  icon: Icons.record_voice_over_outlined,
                  child: TextField(
                    controller: _spokenController,
                    minLines: 2,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Drink water now.',
                      helperText:
                          'If left empty, it will say: "$_fallbackSpokenMessage"',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              _EditorCard(
                title: 'Tone',
                icon: Icons.music_note_rounded,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ToneOption.values
                      .map(
                        (tone) => ChoiceChip(
                          avatar: Icon(_toneIcon(tone), size: 18),
                          label: Text(_toneLabel(tone)),
                          selected: tone == _tone,
                          onSelected: (_) => setState(() => _tone = tone),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 14),
              _EditorCard(
                title: _deliveryMode == DeliveryMode.gentle
                    ? 'Remind again after'
                    : 'Snooze',
                icon: _deliveryMode == DeliveryMode.gentle
                    ? Icons.more_time_rounded
                    : Icons.snooze_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _deliveryMode == DeliveryMode.gentle
                          ? 'Used when you tap “Remind again” on the gentle notification.'
                          : 'Used when you snooze the full-screen alarm or alarm notification.',
                      style: _subtle(context),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [2, 5, 10, 15, 30]
                          .map(
                            (value) => ChoiceChip(
                              label: Text('$value min'),
                              selected: value == _snoozeMinutes,
                              onSelected: (_) =>
                                  setState(() => _snoozeMinutes = value),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (!_canSave)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Add a reminder title before saving.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _canSave ? _save : null,
                  icon: const Icon(Icons.check_rounded),
                  label: Text(editing ? 'Save changes' : 'Save reminder'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditorCard extends StatelessWidget {
  const _EditorCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.softCardGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.line.withValues(alpha: 0.78)),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkWine.withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.darkWine.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.darkWine, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _DeliveryModeCard extends StatelessWidget {
  const _DeliveryModeCard({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final DeliveryMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = switch (mode) {
      DeliveryMode.gentle => Icons.notifications_none_rounded,
      DeliveryMode.alarm => Icons.alarm_rounded,
      DeliveryMode.speaking => Icons.record_voice_over_rounded,
    };
    final description = switch (mode) {
      DeliveryMode.gentle => 'A light notification for low-urgency nudges.',
      DeliveryMode.alarm => 'Rings until you acknowledge it.',
      DeliveryMode.speaking =>
        'Speaks your message, then rings until acknowledged.',
    };
    final badges = switch (mode) {
      DeliveryMode.gentle => const ['Light', 'Notification'],
      DeliveryMode.alarm => const ['Full-screen', 'Acknowledge'],
      DeliveryMode.speaking => const ['Speaks', 'Full-screen'],
    };
    final accent = switch (mode) {
      DeliveryMode.gentle => const Color(0xff829f98),
      DeliveryMode.alarm => AppColors.darkWine,
      DeliveryMode.speaking => AppColors.mutedWine,
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
                  colors: [
                    accent.withValues(alpha: 0.14),
                    AppColors.brightSnow,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : const LinearGradient(
                  colors: [AppColors.brightSnow, AppColors.linen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? accent : AppColors.line,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.brightSnow.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _deliveryLabel(mode),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: AppColors.ink,
                              ),
                        ),
                      ),
                      if (selected)
                        Icon(
                          Icons.check_circle_rounded,
                          color: accent,
                          size: 20,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(description, style: _subtle(context)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: badges
                        .map(
                          (badge) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              badge,
                              style: TextStyle(
                                color: accent,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        )
                        .toList(),
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
