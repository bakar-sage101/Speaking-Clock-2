package com.example.speaking_clock

import android.app.Service
import android.content.Intent
import android.media.AudioAttributes
import android.media.Ringtone
import android.media.RingtoneManager
import android.net.Uri
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import java.util.concurrent.TimeUnit

class AlarmPlaybackService : Service(), TextToSpeech.OnInitListener {
    private var textToSpeech: TextToSpeech? = null
    private var ringtone: Ringtone? = null
    private val handler = Handler(Looper.getMainLooper())
    private var title = "Reminder"
    private var spoken = false
    private var spokenMessage = ""
    private var toneId = "softChime"
    private var id = 0
    private var snoozeMinutes = 10
    private var repeatRule = "Once"

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == actionStop) {
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()
            return START_NOT_STICKY
        }
        if (intent?.action == actionSnooze) {
            handleSnooze(intent)
            return START_NOT_STICKY
        }
        stopPlayback()
        id = intent?.getIntExtra(AlarmReceiver.extraId, 0) ?: 0
        title = intent?.getStringExtra(AlarmReceiver.extraTitle) ?: "Reminder"
        spoken = intent?.getBooleanExtra(AlarmReceiver.extraSpoken, false) ?: false
        spokenMessage = intent?.getStringExtra(AlarmReceiver.extraSpokenMessage).orEmpty()
        toneId = intent?.getStringExtra(AlarmReceiver.extraToneId) ?: "softChime"
        snoozeMinutes = intent?.getIntExtra(AlarmReceiver.extraSnoozeMinutes, 10) ?: 10
        repeatRule = intent?.getStringExtra(AlarmReceiver.extraRepeatRule) ?: "Once"
        startForeground(notificationId, AlarmNotificationHelper.createReliableNotification(this, id, title, spoken, spokenMessage, toneId, snoozeMinutes, repeatRule))
        if (spoken) {
            textToSpeech = TextToSpeech(this, this)
        } else {
            playTone()
        }
        return START_NOT_STICKY
    }

    override fun onInit(status: Int) {
        if (status != TextToSpeech.SUCCESS) {
            playToneAfterSpeechGap()
            return
        }
        textToSpeech?.setAudioAttributes(
            AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_ALARM)
                .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                .build(),
        )
        textToSpeech?.setOnUtteranceProgressListener(
            object : UtteranceProgressListener() {
                override fun onStart(utteranceId: String?) = Unit

                override fun onDone(utteranceId: String?) {
                    playToneAfterSpeechGap()
                }

                @Deprecated("Deprecated in Java")
                override fun onError(utteranceId: String?) {
                    playToneAfterSpeechGap()
                }
            },
        )
        val message = spokenMessage.ifBlank { "It is time for $title" }
        textToSpeech?.speak(message, TextToSpeech.QUEUE_FLUSH, null, "speaking_clock_alarm")
    }

    override fun onDestroy() {
        stopPlayback()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun playTone() {
        if (toneId == "vibrationOnly") return
        ringtone?.stop()
        val toneUri = toneUriFor(toneId)
        ringtone = RingtoneManager.getRingtone(this, toneUri)?.apply {
            audioAttributes = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_ALARM)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.P) {
                isLooping = true
            }
            play()
        }
    }

    private fun playToneAfterSpeechGap() {
        handler.postDelayed({ playTone() }, speechToAlarmGapMillis)
    }

    private fun stopPlayback() {
        handler.removeCallbacksAndMessages(null)
        ringtone?.stop()
        ringtone = null
        textToSpeech?.stop()
        textToSpeech?.shutdown()
        textToSpeech = null
    }

    private fun handleSnooze(intent: Intent) {
        val snoozeId = intent.getIntExtra(AlarmReceiver.extraId, id)
        val snoozeTitle = intent.getStringExtra(AlarmReceiver.extraTitle) ?: title
        val snoozeSpoken = intent.getBooleanExtra(AlarmReceiver.extraSpoken, spoken)
        val snoozeSpokenMessage = intent.getStringExtra(AlarmReceiver.extraSpokenMessage) ?: spokenMessage
        val snoozeToneId = intent.getStringExtra(AlarmReceiver.extraToneId) ?: toneId
        val snoozeDurationMinutes = intent.getIntExtra(AlarmReceiver.extraSnoozeMinutes, snoozeMinutes)
        val snoozeRepeatRule = intent.getStringExtra(AlarmReceiver.extraRepeatRule) ?: repeatRule
        stopPlayback()
        val triggerAt = System.currentTimeMillis() + TimeUnit.MINUTES.toMillis(snoozeDurationMinutes.toLong())
        AlarmScheduler.schedule(this, snoozeId, triggerAt, snoozeTitle, true, snoozeSpoken, snoozeSpokenMessage, snoozeToneId, snoozeDurationMinutes, snoozeRepeatRule)
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    private fun toneUriFor(toneId: String): Uri {
        val type = when (toneId) {
            "softChime", "calmWater" -> RingtoneManager.TYPE_NOTIFICATION
            else -> RingtoneManager.TYPE_ALARM
        }
        return RingtoneManager.getDefaultUri(type)
            ?: android.provider.Settings.System.DEFAULT_ALARM_ALERT_URI
    }

    companion object {
        const val actionStop = "com.example.speaking_clock.STOP_ALARM"
        const val actionSnooze = "com.example.speaking_clock.SNOOZE_ALARM"
        private const val notificationId = 2101
        private const val speechToAlarmGapMillis = 2000L
    }
}
