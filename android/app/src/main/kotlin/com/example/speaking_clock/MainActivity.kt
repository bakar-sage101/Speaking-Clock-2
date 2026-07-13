package com.example.speaking_clock

import android.app.AlarmManager
import android.content.Intent
import android.media.AudioManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "speaking_clock/reliability"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getStatus" -> result.success(AlarmReadiness.status(this))
                    "requestNotifications" -> requestNotifications(result)
                    "requestExactAlarms" -> requestExactAlarms(result)
                    "openDndSettings" -> openDndSettings(result)
                    "openFullScreenIntentSettings" -> openFullScreenIntentSettings(result)
                    "scheduleAlarm" -> scheduleAlarm(call.arguments as? Map<*, *>, result)
                    "cancelAlarm" -> cancelAlarm(call.arguments as? Map<*, *>, result)
                    else -> result.notImplemented()
                }
            }
    }

    private fun requestNotifications(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            requestPermissions(arrayOf(android.Manifest.permission.POST_NOTIFICATIONS), 901)
        }
        result.success(null)
    }

    private fun requestExactAlarms(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            startActivity(
                Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM).apply {
                    data = Uri.parse("package:$packageName")
                },
            )
        }
        result.success(null)
    }

    private fun openDndSettings(result: MethodChannel.Result) {
        AlarmNotificationHelper.ensureChannels(this)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startActivity(
                Intent(Settings.ACTION_CHANNEL_NOTIFICATION_SETTINGS).apply {
                    putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                    putExtra(Settings.EXTRA_CHANNEL_ID, AlarmNotificationHelper.reliableChannelId)
                },
            )
        } else {
            startActivity(Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS))
        }
        result.success(null)
    }

    private fun openFullScreenIntentSettings(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startActivity(
                Intent(Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT).apply {
                    data = Uri.parse("package:$packageName")
                },
            )
        } else {
            startActivity(
                Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
                    putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                },
            )
        }
        result.success(null)
    }

    private fun scheduleAlarm(arguments: Map<*, *>?, result: MethodChannel.Result) {
        val id = arguments?.get("id") as? Int
        val triggerAtMillis = arguments?.get("triggerAtMillis") as? Long
        val title = arguments?.get("title") as? String
        val alarmStyle = arguments?.get("alarmStyle") as? Boolean ?: false
        val spoken = arguments?.get("spoken") as? Boolean ?: false
        val spokenMessage = arguments?.get("spokenMessage") as? String ?: ""
        val toneId = arguments?.get("toneId") as? String ?: "softChime"
        val snoozeMinutes = arguments?.get("snoozeMinutes") as? Int ?: 10
        val repeatRule = arguments?.get("repeatRule") as? String ?: "Once"
        if (id == null || triggerAtMillis == null || title == null) {
            result.error("invalid_arguments", "An id, title, and trigger time are required.", null)
            return
        }
        if (!AlarmReadiness.canScheduleExactAlarms(this)) {
            result.error("exact_alarm_unavailable", "Exact alarm access has not been granted.", null)
            return
        }
        if (alarmStyle && !AlarmReadiness.isAlarmVolumeAudible(this)) {
            result.error("alarm_volume_muted", "Alarm volume is muted or too low. Raise alarm volume before scheduling a reliable alarm.", null)
            return
        }
        AlarmNotificationHelper.ensureChannels(this)
        AlarmScheduler.schedule(this, id, triggerAtMillis, title, alarmStyle, spoken, spokenMessage, toneId, snoozeMinutes, repeatRule)
        result.success(null)
    }

    private fun cancelAlarm(arguments: Map<*, *>?, result: MethodChannel.Result) {
        val id = arguments?.get("id") as? Int
        if (id == null) {
            result.error("invalid_arguments", "An id is required.", null)
            return
        }
        AlarmScheduler.cancel(this, id)
        result.success(null)
    }
}

object AlarmReadiness {
    fun canScheduleExactAlarms(context: android.content.Context): Boolean {
        val manager = context.getSystemService(AlarmManager::class.java)
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.S || manager.canScheduleExactAlarms()
    }

    fun isAlarmVolumeAudible(context: android.content.Context): Boolean {
        val audioManager = context.getSystemService(AudioManager::class.java)
        val currentVolume = audioManager.getStreamVolume(AudioManager.STREAM_ALARM)
        val minimumVolume = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            audioManager.getStreamMinVolume(AudioManager.STREAM_ALARM)
        } else {
            0
        }
        val isMuted = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            audioManager.isStreamMute(AudioManager.STREAM_ALARM)
        } else {
            false
        }
        return !isMuted && currentVolume > minimumVolume
    }

    fun status(context: android.content.Context): Map<String, Any> {
        AlarmNotificationHelper.ensureChannels(context)
        val notificationsEnabled = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            context.getSystemService(android.app.NotificationManager::class.java).areNotificationsEnabled()
        } else {
            true
        }
        val notificationManager = context.getSystemService(android.app.NotificationManager::class.java)
        val fullScreenIntentEnabled = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            notificationManager.canUseFullScreenIntent()
        } else {
            true
        }
        val reliableAlarmCanBypassDnd = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            notificationManager.getNotificationChannel(AlarmNotificationHelper.reliableChannelId)?.canBypassDnd() ?: false
        } else {
            true
        }
        return mapOf(
            "platform" to "android",
            "notificationsEnabled" to notificationsEnabled,
            "exactAlarmEnabled" to canScheduleExactAlarms(context),
            "dndPolicyAccess" to reliableAlarmCanBypassDnd,
            "alarmVolumeEnabled" to isAlarmVolumeAudible(context),
            "fullScreenIntentEnabled" to fullScreenIntentEnabled,
        )
    }
}
