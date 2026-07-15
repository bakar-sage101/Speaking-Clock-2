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
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(foregroundColor: AppColors.ink),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: _canSave ? _save : null,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(74, 42),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: const Text('Save'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SoftPanel(
                radius: 28,
                padding: const EdgeInsets.all(18),
                gradient: AppColors.signatureHeroGradient,
                borderColor: Colors.transparent,
                shadowOpacity: 0.12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      editing ? 'Edit reminder' : 'Add reminder',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.linen,
                        fontWeight: FontWeight.w900,
                        shadows: _softTextShadow(opacity: 0.3),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Name it, choose the type, then set how strongly it should reach you.',
                      style: TextStyle(
                        color: AppColors.linen.withValues(alpha: 0.82),
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                        shadows: _softTextShadow(opacity: 0.24),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Title',
                      style: _compactFieldLabel(context, light: true),
                    ),
                    const SizedBox(height: 7),
                    TextField(
                      controller: _controller,
                      autofocus: !editing,
                      onChanged: (_) => setState(() {}),
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Drink water',
                        filled: true,
                        fillColor: AppColors.brightSnow.withValues(alpha: 0.88),
                        errorText: _controller.text.isEmpty
                            ? null
                            : _canSave
                            ? null
                            : 'Add a title before saving.',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(
                            color: AppColors.linen,
                            width: 1.4,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Category',
                      style: _compactFieldLabel(context, light: true),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 82,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (context, index) {
                          final type = ReminderType.values[index];
                          return _CategoryPill(
                            type: type,
                            selected: type == _type,
                            onTap: () => setState(() => _type = type),
                            onGradient: true,
                          );
                        },
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemCount: ReminderType.values.length,
                      ),
                    ),
                  ],
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
                        minimumSize: const Size.fromHeight(58),
                        alignment: Alignment.centerLeft,
                        side: BorderSide(
                          color: AppColors.line.withValues(alpha: 0.65),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        backgroundColor: AppColors.brightSnow.withValues(
                          alpha: 0.74,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
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
                            (option) => _EditorChoicePill(
                              label: Text(option),
                              selected: option == _frequency,
                              icon: option == 'Custom minutes'
                                  ? Icons.tune_rounded
                                  : Icons.event_repeat_rounded,
                              onTap: () => setState(() => _frequency = option),
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
                        (tone) => _EditorChoicePill(
                          icon: _toneIcon(tone),
                          label: Text(_toneLabel(tone)),
                          selected: tone == _tone,
                          onTap: () => setState(() => _tone = tone),
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
                            (value) => _EditorChoicePill(
                              label: Text('$value min'),
                              selected: value == _snoozeMinutes,
                              icon: Icons.snooze_rounded,
                              onTap: () =>
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
    return SoftPanel(
      radius: 22,
      padding: const EdgeInsets.all(16),
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

TextStyle _compactFieldLabel(BuildContext context, {bool light = false}) =>
    Theme.of(context).textTheme.labelSmall!.copyWith(
      color: light
          ? AppColors.linen.withValues(alpha: 0.9)
          : AppColors.ink.withValues(alpha: 0.74),
      fontWeight: FontWeight.w900,
      letterSpacing: 0.5,
      shadows: light ? _softTextShadow(opacity: 0.22) : null,
    );

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({
    required this.type,
    required this.selected,
    required this.onTap,
    this.onGradient = false,
  });

  final ReminderType type;
  final bool selected;
  final VoidCallback onTap;
  final bool onGradient;

  @override
  Widget build(BuildContext context) {
    final data = switch (type) {
      ReminderType.water => (SpeakingClockIcon.droplet, AppColors.sage),
      ReminderType.breakTime => (SpeakingClockIcon.stretch, AppColors.sage),
      ReminderType.meeting => (SpeakingClockIcon.calendar, AppColors.darkWine),
      ReminderType.medication => (SpeakingClockIcon.pill, AppColors.mutedWine),
      ReminderType.custom => (SpeakingClockIcon.target, AppColors.ink),
    };
    final color = onGradient
        ? AppColors.darkWine
        : selected
        ? AppColors.sage
        : AppColors.ink;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 76,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: onGradient
              ? AppColors.brightSnow.withValues(alpha: selected ? 0.9 : 0.72)
              : selected
              ? AppColors.sage.withValues(alpha: 0.20)
              : AppColors.brightSnow.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? (onGradient ? AppColors.darkWine : AppColors.sage)
                : (onGradient
                      ? AppColors.brightSnow.withValues(alpha: 0.8)
                      : AppColors.line),
            width: selected ? 1.5 : 1,
          ),
          boxShadow: onGradient
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomReminderIcon(
              icon: data.$1,
              color: onGradient ? color : (selected ? data.$2 : color),
              size: 23,
            ),
            const SizedBox(height: 7),
            Text(
              _label(type),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditorChoicePill extends StatelessWidget {
  const _EditorChoicePill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final Widget label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? AppColors.linen : AppColors.darkWine;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          decoration: BoxDecoration(
            gradient: selected ? AppColors.wineHeroGradient : null,
            color: selected
                ? null
                : AppColors.brightSnow.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? AppColors.darkWine.withValues(alpha: 0.12)
                  : AppColors.line.withValues(alpha: 0.9),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.darkWine.withValues(
                  alpha: selected ? 0.12 : 0.025,
                ),
                blurRadius: selected ? 16 : 8,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 17, color: foreground),
                const SizedBox(width: 7),
              ],
              DefaultTextStyle.merge(
                style: TextStyle(
                  color: foreground,
                  fontWeight: FontWeight.w900,
                  shadows: selected ? _softTextShadow(opacity: 0.24) : null,
                ),
                child: label,
              ),
            ],
          ),
        ),
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
    final foreground = selected ? AppColors.linen : AppColors.ink;
    final mutedForeground = selected
        ? AppColors.linen.withValues(alpha: 0.82)
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.signatureHeroGradient : null,
          color: selected ? null : AppColors.brightSnow.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected
                ? AppColors.darkWine.withValues(alpha: 0.12)
                : AppColors.line,
            width: selected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.darkWine.withValues(
                alpha: selected ? 0.12 : 0.025,
              ),
              blurRadius: selected ? 18 : 10,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.linen.withValues(alpha: 0.16)
                    : accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: selected ? AppColors.linen : accent),
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
                                color: foreground,
                                shadows: selected
                                    ? _softTextShadow(opacity: 0.26)
                                    : null,
                              ),
                        ),
                      ),
                      if (selected)
                        Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.linen,
                          size: 20,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: mutedForeground,
                      fontWeight: FontWeight.w700,
                      height: 1.28,
                      shadows: selected ? _softTextShadow(opacity: 0.22) : null,
                    ),
                  ),
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
                              color: selected
                                  ? AppColors.linen.withValues(alpha: 0.16)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              badge,
                              style: TextStyle(
                                color: selected ? AppColors.linen : accent,
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                                shadows: selected
                                    ? _softTextShadow(opacity: 0.22)
                                    : null,
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
