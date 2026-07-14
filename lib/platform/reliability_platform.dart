import 'package:flutter/services.dart';

class AlarmReadiness {
  const AlarmReadiness({
    required this.platform,
    required this.notificationsEnabled,
    required this.exactAlarmEnabled,
    required this.dndPolicyAccess,
    required this.alarmVolumeEnabled,
    required this.fullScreenIntentEnabled,
  });

  final String platform;
  final bool notificationsEnabled;
  final bool exactAlarmEnabled;
  final bool dndPolicyAccess;
  final bool alarmVolumeEnabled;
  final bool fullScreenIntentEnabled;

  bool get isReady =>
      notificationsEnabled &&
      exactAlarmEnabled &&
      dndPolicyAccess &&
      alarmVolumeEnabled &&
      fullScreenIntentEnabled;

  bool get canScheduleGentleReminders =>
      notificationsEnabled && exactAlarmEnabled;

  bool get canScheduleReliableAlarms =>
      notificationsEnabled && exactAlarmEnabled && alarmVolumeEnabled;

  bool get canScheduleSpokenAlarms => canScheduleReliableAlarms;

  factory AlarmReadiness.fromMap(Map<Object?, Object?> values) =>
      AlarmReadiness(
        platform: values['platform'] as String? ?? 'unknown',
        notificationsEnabled: values['notificationsEnabled'] as bool? ?? false,
        exactAlarmEnabled: values['exactAlarmEnabled'] as bool? ?? false,
        dndPolicyAccess: values['dndPolicyAccess'] as bool? ?? false,
        alarmVolumeEnabled: values['alarmVolumeEnabled'] as bool? ?? false,
        fullScreenIntentEnabled:
            values['fullScreenIntentEnabled'] as bool? ?? false,
      );
}

class ReliabilityPlatform {
  ReliabilityPlatform._();

  static const _channel = MethodChannel('speaking_clock/reliability');

  static Future<AlarmReadiness> getStatus() async {
    final values = await _channel.invokeMapMethod<Object?, Object?>(
      'getStatus',
    );
    return AlarmReadiness.fromMap(values ?? const {});
  }

  static Future<void> requestNotifications() =>
      _channel.invokeMethod<void>('requestNotifications');

  static Future<void> requestExactAlarms() =>
      _channel.invokeMethod<void>('requestExactAlarms');

  static Future<void> openDndSettings() =>
      _channel.invokeMethod<void>('openDndSettings');

  static Future<void> openFullScreenIntentSettings() =>
      _channel.invokeMethod<void>('openFullScreenIntentSettings');

  static Future<void> scheduleAlarm({
    required int id,
    required DateTime triggerAt,
    required String title,
    required bool alarmStyle,
    required bool spoken,
    required String spokenMessage,
    required String toneId,
    required int snoozeMinutes,
    required String repeatRule,
  }) => _channel.invokeMethod<void>('scheduleAlarm', {
    'id': id,
    'triggerAtMillis': triggerAt.millisecondsSinceEpoch,
    'title': title,
    'alarmStyle': alarmStyle,
    'spoken': spoken,
    'spokenMessage': spokenMessage,
    'toneId': toneId,
    'snoozeMinutes': snoozeMinutes,
    'repeatRule': repeatRule,
  });

  static Future<void> cancelAlarm({required int id}) =>
      _channel.invokeMethod<void>('cancelAlarm', {'id': id});
}
