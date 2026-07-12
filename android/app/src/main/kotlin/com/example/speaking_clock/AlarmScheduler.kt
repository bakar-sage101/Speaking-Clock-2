package com.example.speaking_clock

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.util.Log

object AlarmScheduler {
    fun schedule(context: Context, id: Int, triggerAtMillis: Long, title: String, alarmStyle: Boolean, spoken: Boolean, spokenMessage: String, toneId: String, snoozeMinutes: Int, repeatRule: String) {
        val alarmIntent = Intent(context, AlarmReceiver::class.java).apply {
            action = AlarmReceiver.actionFireAlarm
            putExtra(AlarmReceiver.extraTitle, title)
            putExtra(AlarmReceiver.extraId, id)
            putExtra(AlarmReceiver.extraAlarmStyle, alarmStyle)
            putExtra(AlarmReceiver.extraSpoken, spoken)
            putExtra(AlarmReceiver.extraSpokenMessage, spokenMessage)
            putExtra(AlarmReceiver.extraToneId, toneId)
            putExtra(AlarmReceiver.extraSnoozeMinutes, snoozeMinutes)
            putExtra(AlarmReceiver.extraRepeatRule, repeatRule)
            putExtra(AlarmReceiver.extraTriggerAtMillis, triggerAtMillis)
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
            AlarmActivity.intent(context, id, title, spoken, spokenMessage, toneId, snoozeMinutes, repeatRule),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        context.getSystemService(AlarmManager::class.java).setAlarmClock(
            AlarmManager.AlarmClockInfo(triggerAtMillis, showIntent),
            pendingIntent,
        )
        Log.i(tag, "Scheduled alarm id=$id title=$title triggerAtMillis=$triggerAtMillis repeatRule=$repeatRule alarmStyle=$alarmStyle spoken=$spoken")
        ScheduledAlarmStore.save(
            context,
            ScheduledAlarm(
                id = id,
                triggerAtMillis = triggerAtMillis,
                title = title,
                alarmStyle = alarmStyle,
                spoken = spoken,
                spokenMessage = spokenMessage,
                toneId = toneId,
                snoozeMinutes = snoozeMinutes,
                repeatRule = repeatRule,
            ),
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
        ScheduledAlarmStore.remove(context, id)
    }

    private const val tag = "SpeakingClockAlarm"
}
