import 'package:flutter/services.dart';

class AlarmReadiness {
  const AlarmReadiness({
    required this.platform,
    required this.notificationsEnabled,
    required this.exactAlarmEnabled,
    required this.dndPolicyAccess,
    required this.alarmVolumeEnabled,
  });

  final String platform;
  final bool notificationsEnabled;
  final bool exactAlarmEnabled;
  final bool dndPolicyAccess;
  final bool alarmVolumeEnabled;

  bool get isReady =>
      notificationsEnabled &&
      exactAlarmEnabled &&
      dndPolicyAccess &&
      alarmVolumeEnabled;

  factory AlarmReadiness.fromMap(Map<Object?, Object?> values) => AlarmReadiness(
        platform: values['platform'] as String? ?? 'unknown',
        notificationsEnabled: values['notificationsEnabled'] as bool? ?? false,
        exactAlarmEnabled: values['exactAlarmEnabled'] as bool? ?? false,
        dndPolicyAccess: values['dndPolicyAccess'] as bool? ?? false,
        alarmVolumeEnabled: values['alarmVolumeEnabled'] as bool? ?? false,
      );
}

class ReliabilityPlatform {
  ReliabilityPlatform._();

  static const _channel = MethodChannel('speaking_clock/reliability');

  static Future<AlarmReadiness> getStatus() async {
    final values = await _channel.invokeMapMethod<Object?, Object?>('getStatus');
    return AlarmReadiness.fromMap(values ?? const {});
  }

  static Future<void> requestNotifications() =>
      _channel.invokeMethod<void>('requestNotifications');

  static Future<void> requestExactAlarms() =>
      _channel.invokeMethod<void>('requestExactAlarms');

  static Future<void> openDndSettings() =>
      _channel.invokeMethod<void>('openDndSettings');

  static Future<void> scheduleAlarm({
    required int id,
    required DateTime triggerAt,
    required String title,
  }) =>
      _channel.invokeMethod<void>('scheduleAlarm', {
        'id': id,
        'triggerAtMillis': triggerAt.millisecondsSinceEpoch,
        'title': title,
      });
}
