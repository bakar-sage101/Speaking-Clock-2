package com.example.speaking_clock

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != actionFireAlarm) return
        val title = intent.getStringExtra(extraTitle) ?: "Reminder"
        val id = intent.getIntExtra(extraId, 0)
        val alarmStyle = intent.getBooleanExtra(extraAlarmStyle, false)
        val spoken = intent.getBooleanExtra(extraSpoken, false)
        val spokenMessage = intent.getStringExtra(extraSpokenMessage) ?: ""
        val toneId = intent.getStringExtra(extraToneId) ?: "softChime"
        val snoozeMinutes = intent.getIntExtra(extraSnoozeMinutes, 10)
        val repeatRule = intent.getStringExtra(extraRepeatRule) ?: "Once"
        val triggerAtMillis = intent.getLongExtra(extraTriggerAtMillis, System.currentTimeMillis())
        ScheduledAlarmStore.nextTriggerAfter(triggerAtMillis, repeatRule)?.let { nextTrigger ->
            AlarmScheduler.schedule(context, id, nextTrigger, title, alarmStyle, spoken, spokenMessage, toneId, snoozeMinutes, repeatRule)
        } ?: ScheduledAlarmStore.remove(context, id)
        if (!alarmStyle) {
            AlarmNotificationHelper.showGentleReminder(context, id, title)
            return
        }
        val serviceIntent = Intent(context, AlarmPlaybackService::class.java).apply {
            putExtra(extraTitle, title)
            putExtra(extraId, id)
            putExtra(extraSpoken, spoken)
            putExtra(extraSpokenMessage, spokenMessage)
            putExtra(extraToneId, toneId)
            putExtra(extraSnoozeMinutes, snoozeMinutes)
        }
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
            context.startForegroundService(serviceIntent)
        } else {
            context.startService(serviceIntent)
        }
        try {
            context.startActivity(
                AlarmActivity.intent(context, id, title, spoken, spokenMessage, toneId, snoozeMinutes, repeatRule).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                },
            )
            Log.i(tag, "Started AlarmActivity for alarm id=$id")
        } catch (error: RuntimeException) {
            Log.e(tag, "Android blocked AlarmActivity launch for alarm id=$id", error)
        }
    }

    companion object {
        const val actionFireAlarm = "com.example.speaking_clock.FIRE_ALARM"
        const val extraTitle = "title"
        const val extraId = "id"
        const val extraAlarmStyle = "alarm_style"
        const val extraSpoken = "spoken"
        const val extraSpokenMessage = "spoken_message"
        const val extraToneId = "tone_id"
        const val extraSnoozeMinutes = "snooze_minutes"
        const val extraRepeatRule = "repeat_rule"
        const val extraTriggerAtMillis = "trigger_at_millis"
        private const val tag = "SpeakingClockAlarm"
    }
}
