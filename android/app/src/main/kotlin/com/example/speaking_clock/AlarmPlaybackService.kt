package com.example.speaking_clock

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.media.AudioAttributes
import android.os.Build
import android.os.IBinder
import android.speech.tts.TextToSpeech
import androidx.core.app.NotificationCompat

class AlarmPlaybackService : Service(), TextToSpeech.OnInitListener {
    private var textToSpeech: TextToSpeech? = null
    private var title = "Reminder"

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        title = intent?.getStringExtra(AlarmReceiver.extraTitle) ?: "Reminder"
        startForeground(notificationId, createNotification(title))
        textToSpeech = TextToSpeech(this, this)
        return START_NOT_STICKY
    }

    override fun onInit(status: Int) {
        if (status != TextToSpeech.SUCCESS) {
            stopSelf()
            return
        }
        textToSpeech?.setAudioAttributes(
            AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_ALARM)
                .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                .build(),
        )
        textToSpeech?.speak("It is time for $title", TextToSpeech.QUEUE_FLUSH, null, "speaking_clock_alarm")
    }

    override fun onDestroy() {
        textToSpeech?.stop()
        textToSpeech?.shutdown()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createNotification(reminderTitle: String): android.app.Notification {
        val manager = getSystemService(NotificationManager::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(
                NotificationChannel(channelId, "Reliable alarms", NotificationManager.IMPORTANCE_HIGH).apply {
                    description = "Spoken alarms for important Speaking Clock reminders"
                    setBypassDnd(false)
                },
            )
        }
        return NotificationCompat.Builder(this, channelId)
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setContentTitle(reminderTitle)
            .setContentText("Speaking Clock alarm")
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setOngoing(true)
            .build()
    }

    companion object {
        private const val channelId = "reliable_alarms"
        private const val notificationId = 2101
    }
}
