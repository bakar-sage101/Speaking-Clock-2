package com.example.speaking_clock

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED && intent.action != Intent.ACTION_MY_PACKAGE_REPLACED) return
        val now = System.currentTimeMillis()
        ScheduledAlarmStore.all(context).forEach { alarm ->
            val nextTrigger = nextUsableTrigger(alarm.triggerAtMillis, alarm.repeatRule, now)
            if (nextTrigger == null) {
                ScheduledAlarmStore.remove(context, alarm.id)
                return@forEach
            }
            try {
                AlarmScheduler.schedule(
                    context,
                    alarm.id,
                    nextTrigger,
                    alarm.title,
                    alarm.alarmStyle,
                    alarm.spoken,
                    alarm.spokenMessage,
                    alarm.toneId,
                    alarm.snoozeMinutes,
                    alarm.repeatRule,
                )
                Log.i(tag, "Restored alarm id=${alarm.id} for $nextTrigger")
            } catch (error: RuntimeException) {
                Log.e(tag, "Could not restore alarm id=${alarm.id}", error)
            }
        }
    }

    private fun nextUsableTrigger(triggerAtMillis: Long, repeatRule: String, now: Long): Long? {
        var next = triggerAtMillis
        var guard = 0
        while (next <= now && guard < 400) {
            next = ScheduledAlarmStore.nextTriggerAfter(next, repeatRule) ?: return null
            guard += 1
        }
        return if (next > now) next else null
    }

    companion object {
        private const val tag = "SpeakingClockBoot"
    }
}
