package com.example.speaking_clock

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != actionFireAlarm) return
        val serviceIntent = Intent(context, AlarmPlaybackService::class.java).apply {
            putExtra(extraTitle, intent.getStringExtra(extraTitle) ?: "Reminder")
            putExtra(extraId, intent.getIntExtra(extraId, 0))
        }
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
            context.startForegroundService(serviceIntent)
        } else {
            context.startService(serviceIntent)
        }
    }

    companion object {
        const val actionFireAlarm = "com.example.speaking_clock.FIRE_ALARM"
        const val extraTitle = "title"
        const val extraId = "id"
    }
}
