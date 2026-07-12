package com.example.speaking_clock

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Bundle
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.view.WindowManager
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.concurrent.TimeUnit

class AlarmActivity : Activity() {
    private var id = 0
    private var title = "Reminder"
    private var spoken = false
    private var spokenMessage = ""
    private var toneId = "softChime"
    private var snoozeMinutes = 10
    private var repeatRule = "Once"

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
        repeatRule = intent?.getStringExtra(AlarmReceiver.extraRepeatRule) ?: "Once"
    }

    private fun createContentView(): LinearLayout {
        val sage = Color.rgb(95, 127, 103)
        val sageLight = Color.rgb(230, 238, 231)
        val canvas = Color.rgb(247, 247, 243)
        val ink = Color.rgb(24, 33, 27)
        val muted = Color.rgb(70, 78, 72)
        val amber = Color.rgb(200, 137, 69)
        val surface = Color.WHITE

        window.statusBarColor = canvas
        window.navigationBarColor = canvas
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            window.decorView.systemUiVisibility = View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR
        }

        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(dp(24), dp(28), dp(24), dp(28))
            setBackgroundColor(canvas)
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT,
            )
        }

        val content = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
        }

        val iconWrap = LinearLayout(this).apply {
            gravity = Gravity.CENTER
            background = rounded(sageLight, 24)
            elevation = dp(2).toFloat()
        }
        iconWrap.addView(
            ImageView(this).apply {
                setImageResource(android.R.drawable.ic_lock_idle_alarm)
                setColorFilter(sage)
            },
            LinearLayout.LayoutParams(dp(34), dp(34)),
        )
        content.addView(
            iconWrap,
            LinearLayout.LayoutParams(dp(74), dp(74)),
        )

        content.addView(
            TextView(this).apply {
                text = SimpleDateFormat("h:mm a", Locale.getDefault()).format(Date()).uppercase(Locale.getDefault())
                textSize = 42f
                typeface = Typeface.DEFAULT_BOLD
                setTextColor(ink)
                gravity = Gravity.CENTER
                includeFontPadding = false
            },
            LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT,
            ).apply { topMargin = dp(22) },
        )

        val mode = if (spoken) "Speaking Alarm" else "Alarm Reminder"
        content.addView(
            TextView(this).apply {
                text = mode.uppercase(Locale.getDefault())
                textSize = 13f
                typeface = Typeface.DEFAULT_BOLD
                letterSpacing = 0.12f
                setTextColor(sage)
                gravity = Gravity.CENTER
                setPadding(dp(14), dp(8), dp(14), dp(8))
                background = rounded(sageLight, 18)
            },
            LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT,
                ViewGroup.LayoutParams.WRAP_CONTENT,
            ).apply { topMargin = dp(14) },
        )

        val titleBlock = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(dp(10), 0, dp(10), 0)
        }
        titleBlock.addView(
            TextView(this).apply {
                text = title
                textSize = 34f
                typeface = Typeface.DEFAULT_BOLD
                setTextColor(ink)
                gravity = Gravity.CENTER
                includeFontPadding = false
                setLineSpacing(0f, 0.96f)
            },
        )
        if (spoken) {
            titleBlock.addView(
                TextView(this).apply {
                    text = spokenMessage.ifBlank { "It is time for $title" }
                    textSize = 18f
                    setTextColor(muted)
                    gravity = Gravity.CENTER
                    setPadding(0, dp(16), 0, 0)
                    setLineSpacing(dp(3).toFloat(), 1.0f)
                },
            )
        }
        content.addView(
            titleBlock,
            LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT,
            ).apply { topMargin = dp(34) },
        )

        content.addView(
            alarmButton("Acknowledge", sage, Color.WHITE, 22) { acknowledge() },
            LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                dp(58),
            ).apply { topMargin = dp(24) },
        )
        content.addView(
            alarmButton("Snooze $snoozeMinutes min", sageLight, sage, 22, sage, 1) { snooze() },
            LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                dp(56),
            ).apply { topMargin = dp(12) },
        )
        content.addView(
            TextView(this).apply {
                text = "Speaking Clock"
                textSize = 13f
                typeface = Typeface.DEFAULT_BOLD
                setTextColor(amber)
                gravity = Gravity.CENTER
                setPadding(0, dp(24), 0, 0)
            },
        )

        root.addView(
            ScrollView(this).apply {
                isFillViewport = true
                addView(
                    content,
                    ViewGroup.LayoutParams(
                        ViewGroup.LayoutParams.MATCH_PARENT,
                        ViewGroup.LayoutParams.WRAP_CONTENT,
                    ),
                )
            },
            LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT,
            ),
        )
        return root
    }

    private fun alarmButton(label: String, backgroundColor: Int, textColor: Int, radiusDp: Int, strokeColor: Int? = null, strokeWidthDp: Int = 0, action: () -> Unit): TextView {
        return TextView(this).apply {
            text = label
            textSize = 18f
            typeface = Typeface.DEFAULT_BOLD
            setTextColor(textColor)
            gravity = Gravity.CENTER
            isClickable = true
            isFocusable = true
            includeFontPadding = false
            background = rounded(backgroundColor, radiusDp, strokeColor, strokeWidthDp)
            setOnClickListener { action() }
        }
    }

    private fun rounded(color: Int, radiusDp: Int, strokeColor: Int? = null, strokeWidthDp: Int = 0): GradientDrawable {
        return GradientDrawable().apply {
            setColor(color)
            cornerRadius = dp(radiusDp).toFloat()
            if (strokeColor != null && strokeWidthDp > 0) {
                setStroke(dp(strokeWidthDp), strokeColor)
            }
        }
    }

    private fun dp(value: Int): Int {
        return (value * resources.displayMetrics.density).toInt()
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
        AlarmScheduler.schedule(this, id, triggerAt, title, true, spoken, spokenMessage, toneId, snoozeMinutes, repeatRule)
        finishAndRemoveTask()
    }

    companion object {
        fun intent(context: Context, id: Int, title: String, spoken: Boolean, spokenMessage: String, toneId: String, snoozeMinutes: Int, repeatRule: String = "Once"): Intent {
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
                putExtra(AlarmReceiver.extraRepeatRule, repeatRule)
            }
        }
    }
}
