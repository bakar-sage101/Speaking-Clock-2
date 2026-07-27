part of '../../main.dart';

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

  DateTime get _selectedTriggerAt => _triggerForTime(_time);

  bool get _firesToday {
    final now = DateTime.now();
    final t = _selectedTriggerAt;
    return t.year == now.year && t.month == now.month && t.day == now.day;
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
      _frequency = _repeatOptions.contains(repeatRule) ? repeatRule : 'Every day';
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
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.brass,
              onPrimary: Color(0xff1A1205),
              surface: AppColors.surfaceRaised,
              onSurface: AppColors.bone,
            ),
            timePickerTheme: TimePickerThemeData(
              backgroundColor: AppColors.surface,
              hourMinuteColor: AppColors.brass.withValues(alpha: 0.16),
              hourMinuteTextColor: AppColors.bone,
              dayPeriodColor: AppColors.brass.withValues(alpha: 0.20),
              dayPeriodTextColor: AppColors.bone,
              dialBackgroundColor: AppColors.ink,
              dialHandColor: AppColors.brass,
              dialTextColor: AppColors.bone,
              entryModeIconColor: AppColors.brass,
              helpTextStyle: _mono(size: 11, color: AppColors.boneDim, spacing: 1.6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            ),
          ),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
            child: child ?? const SizedBox.shrink(),
          ),
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
        createdAtMillis: reminder?.createdAtMillis ?? now.millisecondsSinceEpoch,
        updatedAtMillis: now.millisecondsSinceEpoch,
      ),
    );
  }

  // ---- focused pickers -------------------------------------------------

  Future<void> _openRepeat() async {
    await _sheet(
      title: 'Repeat',
      builder: (context, setSheet) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final option in _repeatOptions)
            _SheetOption(
              icon: option == 'Custom minutes'
                  ? Icons.tune_rounded
                  : option == 'Once'
                  ? Icons.looks_one_outlined
                  : Icons.event_repeat_rounded,
              label: option == 'Custom minutes' ? 'Every few minutes' : option,
              sub: switch (option) {
                'Once' => 'Fires one time, then done',
                'Every day' => 'Same time, daily',
                'Weekdays' => 'Mon–Fri, skips the weekend',
                _ => 'First at ${_formatTime12(_time)}, then repeats',
              },
              selected: _frequency == option,
              onTap: () => setSheet(() => _frequency = option),
            ),
          if (_frequency == 'Custom minutes') ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Text('Repeat every', style: TextStyle(color: AppColors.boneDim, fontSize: 13)),
                const Spacer(),
                _Stepper(
                  value: _customRepeatMinutes,
                  onChanged: (v) => setSheet(
                    () => _customRepeatController.text = '${v.clamp(1, 1440)}',
                  ),
                  suffix: 'min',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 7,
              children: [2, 25, 90, 120]
                  .map(
                    (v) => _MiniPill(
                      label: '$v',
                      selected: _customRepeatMinutes == v,
                      onTap: () => setSheet(() => _customRepeatController.text = '$v'),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            Text(
              'The first reminder stays at the time you chose. After that it repeats on this interval until you pause it.',
              style: TextStyle(color: AppColors.boneDim, fontSize: 12, height: 1.4),
            ),
          ],
        ],
      ),
    );
    setState(() {});
  }

  Future<void> _openTone() async {
    await _sheet(
      title: 'Tone',
      builder: (context, setSheet) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final tone in ToneOption.values)
            _SheetOption(
              icon: _toneIcon(tone),
              label: _toneLabel(tone),
              sub: tone == ToneOption.vibrationOnly ? 'Silent — buzz pattern' : null,
              selected: _tone == tone,
              onTap: () => setSheet(() => _tone = tone),
            ),
        ],
      ),
    );
    setState(() {});
  }

  Future<void> _openSnooze() async {
    final gentle = _deliveryMode == DeliveryMode.gentle;
    await _sheet(
      title: gentle ? 'Remind again after' : 'Snooze',
      builder: (context, setSheet) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            gentle
                ? 'Used when you tap “Remind again” on the gentle notification.'
                : 'Used when you snooze the full-screen alarm.',
            style: TextStyle(color: AppColors.boneDim, fontSize: 12.5, height: 1.4),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [2, 5, 10, 15, 30]
                .map(
                  (v) => _MiniPill(
                    label: '$v min',
                    selected: _snoozeMinutes == v,
                    onTap: () => setSheet(() => _snoozeMinutes = v),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
    setState(() {});
  }

  Future<void> _sheet({
    required String title,
    required Widget Function(BuildContext, StateSetter) builder,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheet) => SafeArea(
          top: false,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
              border: Border(top: BorderSide(color: AppColors.line)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 4,
                  width: 36,
                  decoration: BoxDecoration(
                    color: AppColors.line2,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 12),
                Text(title, style: _serif(size: 20, color: AppColors.bone)),
                const SizedBox(height: 12),
                builder(context, setSheet),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.brass,
                      foregroundColor: const Color(0xff1A1205),
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---- build -----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final editing = widget.reminder != null;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final color = _intensityColor(_deliveryMode);
    final title = _controller.text.trim();
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(18, 8, 18, bottomInset + 16),
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: AppColors.line),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  height: 4,
                  width: 36,
                  decoration: BoxDecoration(
                    color: AppColors.line2,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // top bar
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(foregroundColor: AppColors.boneDim),
                    child: const Text('Cancel'),
                  ),
                  Expanded(
                    child: Text(
                      editing ? 'Edit reminder' : 'New reminder',
                      textAlign: TextAlign.center,
                      style: _serif(size: 18, color: AppColors.bone),
                    ),
                  ),
                  TextButton(
                    onPressed: _canSave ? _save : null,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.brass,
                      disabledForegroundColor: AppColors.boneDim.withValues(alpha: 0.4),
                    ),
                    child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // live preview
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.line),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color.withValues(alpha: 0.10), Colors.transparent],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      height: 46,
                      width: 46,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: CustomReminderIcon(
                          icon: _categoryIcon(_type),
                          color: color,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title.isEmpty ? 'New reminder' : title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _serif(
                              size: 18,
                              color: title.isEmpty ? AppColors.boneDim : AppColors.bone,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${_deliveryShortLabel(_deliveryMode)} · ${_formatTime12(_time)} · $_selectedRepeatRule',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _mono(size: 10, color: AppColors.boneDim, spacing: 0.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // title
              _label('TITLE'),
              TextField(
                controller: _controller,
                autofocus: !editing,
                onChanged: (_) => setState(() {}),
                cursorColor: AppColors.brass,
                style: const TextStyle(
                  color: AppColors.bone,
                  fontWeight: FontWeight.w600,
                  fontSize: 19,
                ),
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  isDense: true,
                  filled: false,
                  hintText: 'Drink water',
                  hintStyle: TextStyle(color: AppColors.boneDim.withValues(alpha: 0.6)),
                  contentPadding: const EdgeInsets.only(bottom: 9, top: 2),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.line2),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.brass, width: 1.4),
                  ),
                ),
              ),
              // intensity
              _label('HOW SHOULD IT REACH YOU?'),
              Row(
                children: [
                  for (final mode in DeliveryMode.values) ...[
                    Expanded(
                      child: _Segment(
                        mode: mode,
                        selected: _deliveryMode == mode,
                        onTap: () => setState(() => _deliveryMode = mode),
                      ),
                    ),
                    if (mode != DeliveryMode.values.last) const SizedBox(width: 8),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Text(
                _deliveryDescription(_deliveryMode),
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.boneDim, fontSize: 12.5, height: 1.35),
              ),
              // details grid
              _label('DETAILS'),
              Row(
                children: [
                  Expanded(
                    child: _DetailTile(
                      icon: Icons.schedule_rounded,
                      label: 'WHEN',
                      value: _formatTime12(_time),
                      sub: _firesToday ? 'today' : 'tomorrow',
                      onTap: _pickTime,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: _DetailTile(
                      icon: Icons.repeat_rounded,
                      label: 'REPEAT',
                      value: _frequency == 'Custom minutes'
                          ? 'Every $_customRepeatMinutes'
                          : _frequency,
                      sub: _frequency == 'Custom minutes' ? 'min' : null,
                      onTap: _openRepeat,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Row(
                children: [
                  Expanded(
                    child: _DetailTile(
                      icon: Icons.music_note_rounded,
                      label: 'TONE',
                      value: _toneLabel(_tone),
                      onTap: _openTone,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: _DetailTile(
                      icon: _deliveryMode == DeliveryMode.gentle
                          ? Icons.more_time_rounded
                          : Icons.snooze_rounded,
                      label: _deliveryMode == DeliveryMode.gentle ? 'REMIND' : 'SNOOZE',
                      value: '$_snoozeMinutes',
                      sub: 'min',
                      onTap: _openSnooze,
                    ),
                  ),
                ],
              ),
              // spoken message
              if (_deliveryMode == DeliveryMode.speaking) ...[
                _label('WHAT SHOULD IT SAY?'),
                TextField(
                  controller: _spokenController,
                  minLines: 2,
                  maxLines: 4,
                  cursorColor: AppColors.speaking,
                  style: TextStyle(
                    color: AppColors.bone,
                    fontFamily: 'serif',
                    fontStyle: FontStyle.italic,
                    fontSize: 16,
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.surface,
                    hintText: 'Time to drink some water.',
                    hintStyle: TextStyle(
                      color: AppColors.boneDim,
                      fontFamily: 'serif',
                      fontStyle: FontStyle.italic,
                    ),
                    helperMaxLines: 2,
                    helperText: 'If left empty, it will say: "$_fallbackSpokenMessage"',
                    helperStyle: _mono(size: 9.5, color: AppColors.boneDim, spacing: 0.2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.line2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.line2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.speaking, width: 1.3),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    for (final ex in const [
                      '“Drink water now.”',
                      '“Meeting in 10 minutes.”',
                      '“Take your medication.”',
                    ])
                      GestureDetector(
                        onTap: () => setState(
                          () => _spokenController.text = ex.replaceAll('“', '').replaceAll('”', ''),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.line2, style: BorderStyle.solid),
                          ),
                          child: Text(ex, style: TextStyle(color: AppColors.boneDim, fontSize: 11)),
                        ),
                      ),
                  ],
                ),
              ],
              // category
              _label('CATEGORY'),
              SizedBox(
                height: 66,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  itemCount: ReminderType.values.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final type = ReminderType.values[i];
                    return _CatChip(
                      type: type,
                      selected: type == _type,
                      onTap: () => setState(() => _type = type),
                    );
                  },
                ),
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(0, 18, 0, 8),
    child: Text(text, style: _mono(size: 9.5, color: AppColors.boneDim, spacing: 1.8)),
  );
}

String _deliveryDescription(DeliveryMode mode) => switch (mode) {
  DeliveryMode.gentle => 'Gentle — a soft notification you can dismiss.',
  DeliveryMode.alarm => 'Alarm — full-screen, rings until you answer.',
  DeliveryMode.speaking => 'Speaking — speaks your words, then rings.',
};

SpeakingClockIcon _categoryIcon(ReminderType type) => switch (type) {
  ReminderType.water => SpeakingClockIcon.droplet,
  ReminderType.breakTime => SpeakingClockIcon.stretch,
  ReminderType.meeting => SpeakingClockIcon.calendar,
  ReminderType.medication => SpeakingClockIcon.pill,
  ReminderType.custom => SpeakingClockIcon.target,
};

class _Segment extends StatelessWidget {
  const _Segment({required this.mode, required this.selected, required this.onTap});

  final DeliveryMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _intensityColor(mode);
    final icon = switch (mode) {
      DeliveryMode.gentle => Icons.notifications_none_rounded,
      DeliveryMode.alarm => Icons.alarm_rounded,
      DeliveryMode.speaking => Icons.record_voice_over_rounded,
    };
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.10) : AppColors.surface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: selected ? color : AppColors.line,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              height: 36,
              width: 36,
              decoration: BoxDecoration(
                color: selected ? color.withValues(alpha: 0.18) : AppColors.surfaceRaised,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 19, color: selected ? color : AppColors.boneDim),
            ),
            const SizedBox(height: 8),
            Text(
              _deliveryShortLabel(mode),
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: selected ? color : AppColors.boneDim,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.sub,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? sub;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 13, color: AppColors.boneDim),
                const SizedBox(width: 7),
                Text(label, style: _mono(size: 8.5, color: AppColors.boneDim, spacing: 1.4)),
                const Spacer(),
                const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.boneDim),
              ],
            ),
            const SizedBox(height: 8),
            RichText(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                text: value,
                style: const TextStyle(
                  color: AppColors.bone,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
                children: sub == null
                    ? null
                    : [
                        TextSpan(
                          text: ' $sub',
                          style: TextStyle(color: AppColors.boneDim, fontWeight: FontWeight.w400),
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

class _CatChip extends StatelessWidget {
  const _CatChip({required this.type, required this.selected, required this.onTap});

  final ReminderType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: 62,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.brass.withValues(alpha: 0.13) : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppColors.brass : AppColors.line),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomReminderIcon(
              icon: _categoryIcon(type),
              color: selected ? AppColors.brass : AppColors.boneDim,
              size: 20,
            ),
            const SizedBox(height: 6),
            Text(
              _label(type),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.brass : AppColors.boneDim,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  const _SheetOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.sub,
  });

  final IconData icon;
  final String label;
  final String? sub;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.line)),
        ),
        child: Row(
          children: [
            Container(
              height: 30,
              width: 30,
              decoration: BoxDecoration(
                color: selected ? AppColors.brass.withValues(alpha: 0.15) : AppColors.surfaceRaised,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 16, color: selected ? AppColors.brass : AppColors.boneDim),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.bone,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  if (sub != null)
                    Text(sub!, style: TextStyle(color: AppColors.boneDim, fontSize: 11.5)),
                ],
              ),
            ),
            Container(
              height: 20,
              width: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.brass : Colors.transparent,
                border: Border.all(
                  color: selected ? AppColors.brass : AppColors.line2,
                  width: 1.5,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check_rounded, size: 13, color: Color(0xff1A1205))
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.brass : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? AppColors.brass : AppColors.line2),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xff1A1205) : AppColors.boneDim,
            fontWeight: FontWeight.w700,
            fontSize: 13,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.value, required this.onChanged, required this.suffix});

  final int value;
  final ValueChanged<int> onChanged;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _stepBtn('–', () => onChanged(value - 5)),
          Container(
            constraints: const BoxConstraints(minWidth: 62),
            padding: const EdgeInsets.symmetric(vertical: 8),
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              border: Border.symmetric(vertical: BorderSide(color: AppColors.line)),
            ),
            child: Text(
              '$value $suffix',
              style: const TextStyle(
                color: AppColors.bone,
                fontWeight: FontWeight.w700,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
          _stepBtn('+', () => onChanged(value + 5)),
        ],
      ),
    );
  }

  Widget _stepBtn(String glyph, VoidCallback onTap) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
      child: Text(glyph, style: const TextStyle(color: AppColors.brass, fontSize: 18)),
    ),
  );
}
