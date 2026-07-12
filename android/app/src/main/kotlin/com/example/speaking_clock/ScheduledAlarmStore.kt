package com.example.speaking_clock

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar
import java.util.concurrent.TimeUnit

data class ScheduledAlarm(
    val id: Int,
    val triggerAtMillis: Long,
    val title: String,
    val alarmStyle: Boolean,
    val spoken: Boolean,
    val spokenMessage: String,
    val toneId: String,
    val snoozeMinutes: Int,
    val repeatRule: String,
)

object ScheduledAlarmStore {
    private const val preferencesName = "speaking_clock_scheduled_alarms"
    private const val alarmsKey = "alarms"

    fun save(context: Context, alarm: ScheduledAlarm) {
        val alarms = all(context).filterNot { it.id == alarm.id } + alarm
        write(context, alarms)
    }

    fun remove(context: Context, id: Int) {
        write(context, all(context).filterNot { it.id == id })
    }

    fun all(context: Context): List<ScheduledAlarm> {
        val raw = context.getSharedPreferences(preferencesName, Context.MODE_PRIVATE).getString(alarmsKey, "[]") ?: "[]"
        val array = JSONArray(raw)
        return buildList {
            for (index in 0 until array.length()) {
                val item = array.optJSONObject(index) ?: continue
                add(
                    ScheduledAlarm(
                        id = item.optInt("id"),
                        triggerAtMillis = item.optLong("triggerAtMillis"),
                        title = item.optString("title", "Reminder"),
                        alarmStyle = item.optBoolean("alarmStyle", false),
                        spoken = item.optBoolean("spoken", false),
                        spokenMessage = item.optString("spokenMessage", ""),
                        toneId = item.optString("toneId", "softChime"),
                        snoozeMinutes = item.optInt("snoozeMinutes", 10),
                        repeatRule = item.optString("repeatRule", "Once"),
                    ),
                )
            }
        }
    }

    fun nextTriggerAfter(previousTriggerAtMillis: Long, repeatRule: String): Long? {
        customMinuteRepeat(repeatRule)?.let { minutes ->
            return previousTriggerAtMillis + TimeUnit.MINUTES.toMillis(minutes.toLong())
        }
        return when (repeatRule) {
            "Every day" -> previousTriggerAtMillis + TimeUnit.DAYS.toMillis(1)
            "Weekdays" -> nextWeekdayTrigger(previousTriggerAtMillis)
            else -> null
        }
    }

    private fun customMinuteRepeat(repeatRule: String): Int? {
        val match = Regex("^Every\\s+(\\d+)\\s+min$", RegexOption.IGNORE_CASE).find(repeatRule.trim()) ?: return null
        val minutes = match.groupValues.getOrNull(1)?.toIntOrNull() ?: return null
        return minutes.takeIf { it > 0 }
    }

    private fun nextWeekdayTrigger(previousTriggerAtMillis: Long): Long {
        val calendar = Calendar.getInstance().apply {
            timeInMillis = previousTriggerAtMillis
            add(Calendar.DAY_OF_YEAR, 1)
        }
        while (calendar.get(Calendar.DAY_OF_WEEK) == Calendar.SATURDAY || calendar.get(Calendar.DAY_OF_WEEK) == Calendar.SUNDAY) {
            calendar.add(Calendar.DAY_OF_YEAR, 1)
        }
        return calendar.timeInMillis
    }

    private fun write(context: Context, alarms: List<ScheduledAlarm>) {
        val array = JSONArray()
        alarms.forEach { alarm ->
            array.put(
                JSONObject()
                    .put("id", alarm.id)
                    .put("triggerAtMillis", alarm.triggerAtMillis)
                    .put("title", alarm.title)
                    .put("alarmStyle", alarm.alarmStyle)
                    .put("spoken", alarm.spoken)
                    .put("spokenMessage", alarm.spokenMessage)
                    .put("toneId", alarm.toneId)
                    .put("snoozeMinutes", alarm.snoozeMinutes)
                    .put("repeatRule", alarm.repeatRule),
            )
        }
        context.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
            .edit()
            .putString(alarmsKey, array.toString())
            .apply()
    }
}
