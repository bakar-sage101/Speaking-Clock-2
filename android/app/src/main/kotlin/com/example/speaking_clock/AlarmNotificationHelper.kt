package com.example.speaking_clock

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

object AlarmNotificationHelper {
    const val reliableChannelId = "reliable_alarms_v4"
    private const val gentleChannelId = "gentle_reminders"

    fun ensureChannels(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val manager = context.getSystemService(NotificationManager::class.java)
        val canBypassDnd = manager.isNotificationPolicyAccessGranted

        manager.createNotificationChannel(
            NotificationChannel(reliableChannelId, "Reliable alarms", NotificationManager.IMPORTANCE_HIGH).apply {
                description = "Spoken alarms for important Speaking Clock reminders"
                setBypassDnd(canBypassDnd)
                setSound(null, null)
                enableVibration(true)
                vibrationPattern = reliableAlarmVibrationPattern
            },
        )
        manager.createNotificationChannel(
            NotificationChannel(gentleChannelId, "Gentle reminders", NotificationManager.IMPORTANCE_HIGH).apply {
                description = "Reminder alerts from Speaking Clock"
            },
        )
    }

    fun createReliableNotification(context: Context, id: Int, title: String, spoken: Boolean, spokenMessage: String, toneId: String, snoozeMinutes: Int): Notification {
        ensureChannels(context)
        val acknowledgeIntent = PendingIntent.getService(
            context,
            4101,
            Intent(context, AlarmPlaybackService::class.java).apply {
                action = AlarmPlaybackService.actionStop
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val fullScreenIntent = PendingIntent.getActivity(
            context,
            id,
            AlarmActivity.intent(context, id, title, spoken, spokenMessage, toneId, snoozeMinutes),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        return NotificationCompat.Builder(context, reliableChannelId)
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setContentTitle(title)
            .setContentText("Speaking Clock alarm")
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setContentIntent(fullScreenIntent)
            .setOnlyAlertOnce(true)
            .setDefaults(NotificationCompat.DEFAULT_VIBRATE)
            .setVibrate(reliableAlarmVibrationPattern)
            .setOngoing(true)
            .setFullScreenIntent(fullScreenIntent, true)
            .addAction(android.R.drawable.ic_menu_close_clear_cancel, "Acknowledge", acknowledgeIntent)
            .build()
    }

    fun showGentleReminder(context: Context, id: Int, title: String) {
        ensureChannels(context)
        val notification = NotificationCompat.Builder(context, gentleChannelId)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle(title)
            .setContentText("Speaking Clock reminder")
            .setCategory(NotificationCompat.CATEGORY_REMINDER)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .build()
        NotificationManagerCompat.from(context).notify(id, notification)
    }

    private val reliableAlarmVibrationPattern = longArrayOf(0, 350, 150, 350)
}
