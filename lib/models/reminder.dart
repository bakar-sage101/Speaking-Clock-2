part of '../main.dart';

enum ReminderType { water, breakTime, meeting, medication, custom }

enum DeliveryMode { gentle, alarm, speaking }

enum ToneOption {
  softChime,
  classicAlarm,
  digitalBeep,
  morningBell,
  calmWater,
  vibrationOnly,
}

class Reminder {
  const Reminder({
    required this.id,
    required this.title,
    required this.time,
    required this.detail,
    required this.type,
    this.deliveryMode = DeliveryMode.gentle,
    this.spokenMessage = '',
    this.tone = ToneOption.softChime,
    this.enabled = true,
    this.snoozeMinutes = 10,
    this.triggerAtMillis,
    this.createdAtMillis,
    this.updatedAtMillis,
  });

  final String id;
  final String title;
  final String time;
  final String detail;
  final ReminderType type;
  final DeliveryMode deliveryMode;
  final String spokenMessage;
  final ToneOption tone;
  final bool enabled;
  final int snoozeMinutes;
  final int? triggerAtMillis;
  final int? createdAtMillis;
  final int? updatedAtMillis;

  bool get isAlarm => deliveryMode != DeliveryMode.gentle;
  bool get isSpeakingAlarm => deliveryMode == DeliveryMode.speaking;

  Reminder copyWith({
    String? title,
    String? time,
    String? detail,
    ReminderType? type,
    DeliveryMode? deliveryMode,
    String? spokenMessage,
    ToneOption? tone,
    bool? enabled,
    int? snoozeMinutes,
    int? triggerAtMillis,
    int? updatedAtMillis,
  }) => Reminder(
    id: id,
    title: title ?? this.title,
    time: time ?? this.time,
    detail: detail ?? this.detail,
    type: type ?? this.type,
    deliveryMode: deliveryMode ?? this.deliveryMode,
    spokenMessage: spokenMessage ?? this.spokenMessage,
    tone: tone ?? this.tone,
    enabled: enabled ?? this.enabled,
    snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
    triggerAtMillis: triggerAtMillis ?? this.triggerAtMillis,
    createdAtMillis: createdAtMillis,
    updatedAtMillis: updatedAtMillis ?? this.updatedAtMillis,
  );

  ReminderRecordsCompanion toCompanion() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return ReminderRecordsCompanion(
      id: Value(id),
      title: Value(title),
      detail: Value(detail),
      type: Value(type.index),
      deliveryMode: Value(deliveryMode.name),
      spokenMessage: Value(spokenMessage),
      toneId: Value(tone.name),
      enabled: Value(enabled),
      snoozeMinutes: Value(snoozeMinutes),
      timeLabel: Value(time),
      triggerAtMillis: Value(triggerAtMillis),
      createdAtMillis: Value(createdAtMillis ?? now),
      updatedAtMillis: Value(now),
    );
  }

  factory Reminder.fromRecord(ReminderRecord record) => Reminder(
    id: record.id,
    title: record.title,
    time: record.timeLabel,
    detail: record.detail,
    type: _enumValue(ReminderType.values, record.type, ReminderType.custom),
    deliveryMode: _deliveryModeFromName(record.deliveryMode),
    spokenMessage: record.spokenMessage,
    tone: _toneFromName(record.toneId),
    enabled: record.enabled,
    snoozeMinutes: record.snoozeMinutes,
    triggerAtMillis: record.triggerAtMillis,
    createdAtMillis: record.createdAtMillis,
    updatedAtMillis: record.updatedAtMillis,
  );
}

class ReminderDraft {
  const ReminderDraft({
    required this.title,
    required this.type,
    required this.deliveryMode,
    required this.repeatRule,
    required this.tone,
    this.spokenMessage = '',
    this.snoozeMinutes = 10,
  });

  final String title;
  final ReminderType type;
  final DeliveryMode deliveryMode;
  final String repeatRule;
  final ToneOption tone;
  final String spokenMessage;
  final int snoozeMinutes;
}
