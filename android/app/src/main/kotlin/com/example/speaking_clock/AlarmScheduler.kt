package com.example.speaking_clock

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent

object AlarmScheduler {
    fun schedule(context: Context, id: Int, triggerAtMillis: Long, title: String, alarmStyle: Boolean, spoken: Boolean, spokenMessage: String, toneId: String, snoozeMinutes: Int) {
        val alarmIntent = Intent(context, AlarmReceiver::class.java).apply {
            action = AlarmReceiver.actionFireAlarm
            putExtra(AlarmReceiver.extraTitle, title)
            putExtra(AlarmReceiver.extraId, id)
            putExtra(AlarmReceiver.extraAlarmStyle, alarmStyle)
            putExtra(AlarmReceiver.extraSpoken, spoken)
            putExtra(AlarmReceiver.extraSpokenMessage, spokenMessage)
            putExtra(AlarmReceiver.extraToneId, toneId)
            putExtra(AlarmReceiver.extraSnoozeMinutes, snoozeMinutes)
        }
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            id,
            alarmIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val showIntent = PendingIntent.getActivity(
            context,
            id,
            AlarmActivity.intent(context, id, title, spoken, spokenMessage, toneId, snoozeMinutes),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        context.getSystemService(AlarmManager::class.java).setAlarmClock(
            AlarmManager.AlarmClockInfo(triggerAtMillis, showIntent),
            pendingIntent,
        )
    }

    fun cancel(context: Context, id: Int) {
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            id,
            Intent(context, AlarmReceiver::class.java).apply {
                action = AlarmReceiver.actionFireAlarm
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        context.getSystemService(AlarmManager::class.java).cancel(pendingIntent)
        pendingIntent.cancel()
    }
}
