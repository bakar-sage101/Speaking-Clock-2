package com.example.speaking_clock

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.os.Build
import android.os.Bundle
import android.view.Gravity
import android.view.ViewGroup
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import java.util.concurrent.TimeUnit

class AlarmActivity : Activity() {
    private var id = 0
    private var title = "Reminder"
    private var spoken = false
    private var spokenMessage = ""
    private var toneId = "softChime"
    private var snoozeMinutes = 10

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        showOverLockScreen()
        readExtras(intent)
        setContentView(createContentView())
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        readExtras(intent)
        setContentView(createContentView())
    }

    private fun showOverLockScreen() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON,
            )
        }
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }

    private fun readExtras(intent: Intent?) {
        id = intent?.getIntExtra(AlarmReceiver.extraId, 0) ?: 0
        title = intent?.getStringExtra(AlarmReceiver.extraTitle) ?: "Reminder"
        spoken = intent?.getBooleanExtra(AlarmReceiver.extraSpoken, false) ?: false
        spokenMessage = intent?.getStringExtra(AlarmReceiver.extraSpokenMessage).orEmpty()
        toneId = intent?.getStringExtra(AlarmReceiver.extraToneId) ?: "softChime"
        snoozeMinutes = intent?.getIntExtra(AlarmReceiver.extraSnoozeMinutes, 10) ?: 10
    }

    private fun createContentView(): LinearLayout {
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(44, 64, 44, 64)
            setBackgroundColor(Color.rgb(247, 247, 243))
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT,
            )
        }
        val mode = if (spoken) "Speaking Alarm" else "Alarm Reminder"
        root.addView(
            TextView(this).apply {
                text = mode
                textSize = 18f
                setTextColor(Color.rgb(95, 127, 103))
                gravity = Gravity.CENTER
            },
        )
        root.addView(
            TextView(this).apply {
                text = title
                textSize = 34f
                setTextColor(Color.rgb(24, 33, 27))
                gravity = Gravity.CENTER
                setPadding(0, 18, 0, 8)
            },
        )
        if (spoken) {
            root.addView(
                TextView(this).apply {
                    text = spokenMessage.ifBlank { "It is time for $title" }
                    textSize = 18f
                    setTextColor(Color.rgb(70, 78, 72))
                    gravity = Gravity.CENTER
                    setPadding(0, 0, 0, 30)
                },
            )
        }
        root.addView(
            Button(this).apply {
                text = "Acknowledge"
                textSize = 18f
                setOnClickListener { acknowledge() }
            },
            LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT,
            ).apply { topMargin = 24 },
        )
        root.addView(
            Button(this).apply {
                text = "Snooze $snoozeMinutes min"
                textSize = 18f
                setOnClickListener { snooze() }
            },
            LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT,
            ).apply { topMargin = 12 },
        )
        return root
    }

    private fun acknowledge() {
        stopService(Intent(this, AlarmPlaybackService::class.java).apply {
            action = AlarmPlaybackService.actionStop
        })
        finishAndRemoveTask()
    }

    private fun snooze() {
        stopService(Intent(this, AlarmPlaybackService::class.java).apply {
            action = AlarmPlaybackService.actionStop
        })
        val triggerAt = System.currentTimeMillis() + TimeUnit.MINUTES.toMillis(snoozeMinutes.toLong())
        AlarmScheduler.schedule(this, id, triggerAt, title, true, spoken, spokenMessage, toneId, snoozeMinutes)
        finishAndRemoveTask()
    }

    companion object {
        fun intent(context: Context, id: Int, title: String, spoken: Boolean, spokenMessage: String, toneId: String, snoozeMinutes: Int): Intent {
            return Intent(context, AlarmActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP or
                    Intent.FLAG_ACTIVITY_NO_USER_ACTION
                putExtra(AlarmReceiver.extraId, id)
                putExtra(AlarmReceiver.extraTitle, title)
                putExtra(AlarmReceiver.extraSpoken, spoken)
                putExtra(AlarmReceiver.extraSpokenMessage, spokenMessage)
                putExtra(AlarmReceiver.extraToneId, toneId)
                putExtra(AlarmReceiver.extraSnoozeMinutes, snoozeMinutes)
            }
        }
    }
}
