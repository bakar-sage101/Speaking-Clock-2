part of '../main.dart';

TextStyle _sectionLabel(BuildContext context) =>
    Theme.of(context).textTheme.labelMedium!.copyWith(
      letterSpacing: 1.2,
      fontWeight: FontWeight.w800,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
TextStyle _subtle(BuildContext context, {bool small = false}) =>
    (small
            ? Theme.of(context).textTheme.bodySmall
            : Theme.of(context).textTheme.bodyMedium)!
        .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);

String _label(ReminderType type) => switch (type) {
  ReminderType.water => 'Water',
  ReminderType.breakTime => 'Break',
  ReminderType.meeting => 'Meeting',
  ReminderType.medication => 'Medication',
  ReminderType.custom => 'Custom',
};

String _deliveryLabel(DeliveryMode mode) => switch (mode) {
  DeliveryMode.gentle => 'Gentle Reminder',
  DeliveryMode.alarm => 'Alarm Reminder',
  DeliveryMode.speaking => 'Speaking Alarm',
};

String _deliveryShortLabel(DeliveryMode mode) => switch (mode) {
  DeliveryMode.gentle => 'Gentle',
  DeliveryMode.alarm => 'Alarm',
  DeliveryMode.speaking => 'Speaking',
};

IconData _deliveryIcon(DeliveryMode mode) => switch (mode) {
  DeliveryMode.gentle => Icons.notifications_none_rounded,
  DeliveryMode.alarm => Icons.alarm_rounded,
  DeliveryMode.speaking => Icons.record_voice_over_rounded,
};

Color _deliveryAccent(DeliveryMode mode) => switch (mode) {
  DeliveryMode.gentle => const Color(0xff829f98),
  DeliveryMode.alarm => AppColors.darkWine,
  DeliveryMode.speaking => AppColors.mutedWine,
};

String _toneLabel(ToneOption tone) => switch (tone) {
  ToneOption.softChime => 'Soft Chime',
  ToneOption.classicAlarm => 'Classic Alarm',
  ToneOption.digitalBeep => 'Digital Beep',
  ToneOption.morningBell => 'Morning Bell',
  ToneOption.calmWater => 'Calm Water',
  ToneOption.vibrationOnly => 'Vibration Only',
};

IconData _toneIcon(ToneOption tone) => switch (tone) {
  ToneOption.softChime => Icons.notifications_none_rounded,
  ToneOption.classicAlarm => Icons.alarm_rounded,
  ToneOption.digitalBeep => Icons.graphic_eq_rounded,
  ToneOption.morningBell => Icons.wb_sunny_outlined,
  ToneOption.calmWater => Icons.water_drop_outlined,
  ToneOption.vibrationOnly => Icons.vibration_rounded,
};

T _enumValue<T>(List<T> values, int index, T fallback) {
  if (index < 0 || index >= values.length) return fallback;
  return values[index];
}

DeliveryMode _deliveryModeFromName(String name) {
  return DeliveryMode.values.firstWhere(
    (mode) => mode.name == name,
    orElse: () => DeliveryMode.gentle,
  );
}

ToneOption _toneFromName(String name) {
  return ToneOption.values.firstWhere(
    (tone) => tone.name == name,
    orElse: () => ToneOption.softChime,
  );
}

List<Reminder> _sortReminders(List<Reminder> reminders) {
  final sorted = [...reminders];
  sorted.sort((a, b) {
    if (a.enabled != b.enabled) return a.enabled ? -1 : 1;
    final aTime = a.triggerAtMillis ?? 1 << 62;
    final bTime = b.triggerAtMillis ?? 1 << 62;
    return aTime.compareTo(bTime);
  });
  return sorted;
}

String _repeatRule(Reminder reminder) {
  return reminder.detail.split(' · ').first;
}

String _greeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}

String _scheduleBlockedMessage(Reminder reminder, AlarmReadiness readiness) {
  if (!readiness.notificationsEnabled) {
    return 'Reminder saved, but notifications are off. Allow notifications before it can fire.';
  }
  if (!readiness.exactAlarmEnabled) {
    return 'Reminder saved, but exact alarms are off. Allow exact alarms before it can fire on time.';
  }
  if (reminder.isAlarm && !readiness.alarmVolumeEnabled) {
    return 'Reminder saved, but alarm volume is muted or too low. Raise alarm volume before relying on ${_deliveryLabel(reminder.deliveryMode)}.';
  }
  return 'Reminder saved, but this device is not ready to schedule it yet.';
}

String _friendlyDate(DateTime date) {
  const weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
}

List<String> _readinessWarnings(AlarmReadiness? readiness) {
  if (readiness == null) return const [];
  final warnings = <String>[];
  if (!readiness.notificationsEnabled) {
    warnings.add('Notifications are off, so reminders may not appear.');
  }
  if (!readiness.exactAlarmEnabled) {
    warnings.add(
      'Exact alarms are off, so important alarms may not fire on time.',
    );
  }
  if (!readiness.fullScreenIntentEnabled) {
    warnings.add(
      'Full-screen alarms are off, so lock-screen alarm screens may not appear.',
    );
  }
  if (!readiness.alarmVolumeEnabled) {
    warnings.add(
      'Alarm volume is muted or too low, so speech and alarm sound may not be audible.',
    );
  }
  if (!readiness.dndPolicyAccess) {
    warnings.add(
      'Reliable alarms cannot interrupt DND. Android alarms may still fire, but allow this for the safest DND behavior.',
    );
  }
  return warnings;
}

TimeOfDay _defaultReminderTime() {
  final now = DateTime.now().add(const Duration(minutes: 5));
  return TimeOfDay(hour: now.hour, minute: now.minute);
}

DateTime _triggerForTime(TimeOfDay time) {
  final now = DateTime.now();
  var triggerAt = DateTime(
    now.year,
    now.month,
    now.day,
    time.hour,
    time.minute,
  );
  if (!triggerAt.isAfter(now)) {
    triggerAt = triggerAt.add(const Duration(days: 1));
  }
  return triggerAt;
}

String _formatTime12(TimeOfDay time) {
  final period = time.hour >= 12 ? 'PM' : 'AM';
  final hour12 = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour12:$minute $period';
}

int? _customRepeatMinutesFromRule(String rule) {
  final match = RegExp(
    r'^Every\s+(\d+)\s+min$',
    caseSensitive: false,
  ).firstMatch(rule.trim());
  if (match == null) return null;
  final minutes = int.tryParse(match.group(1) ?? '');
  if (minutes == null || minutes <= 0) return null;
  return minutes;
}

TimeOfDay? _parseTimeLabel(String value) {
  final normalized = value.trim().toUpperCase();
  final match = RegExp(
    r'^(\d{1,2}):(\d{2})(?:\s*(AM|PM))?$',
  ).firstMatch(normalized);
  if (match == null) return null;
  var hour = int.tryParse(match.group(1) ?? '');
  final minute = int.tryParse(match.group(2) ?? '');
  if (hour == null || minute == null || minute > 59) return null;
  final period = match.group(3);
  if (period == 'PM' && hour < 12) hour += 12;
  if (period == 'AM' && hour == 12) hour = 0;
  if (hour > 23) return null;
  return TimeOfDay(hour: hour, minute: minute);
}
