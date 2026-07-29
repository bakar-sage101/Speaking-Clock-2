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
        val ink = Color.rgb(11, 12, 16)
        val surfaceGlass = Color.argb(18, 255, 255, 255)
        val line = Color.argb(28, 255, 255, 255)
        val bone = Color.rgb(236, 234, 227)
        val boneDim = Color.argb(158, 236, 234, 227)
        val destructive = Color.rgb(240, 115, 90)
        val brass = Color.rgb(220, 182, 94)
        val aura = if (spoken) Color.rgb(165, 136, 230) else Color.rgb(240, 115, 90)
        val alarmVolumeMuted = !AlarmReadiness.isAlarmVolumeAudible(this)

        window.statusBarColor = ink
        window.navigationBarColor = ink
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            window.decorView.systemUiVisibility = 0
        }

        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(dp(24), dp(28), dp(24), dp(28))
            background = auraBackground(aura)
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
            background = rounded(surfaceGlass, 30, line, 1)
            elevation = dp(8).toFloat()
        }
        iconWrap.addView(
            ImageView(this).apply {
                setImageResource(android.R.drawable.ic_lock_idle_alarm)
                setColorFilter(Color.WHITE)
            },
            LinearLayout.LayoutParams(dp(38), dp(38)),
        )
        content.addView(
            iconWrap,
            LinearLayout.LayoutParams(dp(82), dp(82)),
        )

        content.addView(
            TextView(this).apply {
                text = SimpleDateFormat("h:mm a", Locale.getDefault()).format(Date()).uppercase(Locale.getDefault())
                textSize = 42f
                typeface = Typeface.DEFAULT_BOLD
                setTextColor(bone)
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
                textSize = 12f
                typeface = Typeface.MONOSPACE
                letterSpacing = 0.18f
                setTextColor(brass)
                gravity = Gravity.CENTER
                setPadding(dp(14), dp(8), dp(14), dp(8))
                background = rounded(surfaceGlass, 18, line, 1)
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
                setTextColor(bone)
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
                    typeface = Typeface.create(Typeface.SERIF, Typeface.ITALIC)
                    setTextColor(boneDim)
                    gravity = Gravity.CENTER
                    setPadding(0, dp(16), 0, 0)
                    setLineSpacing(dp(3).toFloat(), 1.0f)
                },
            )
        }
        if (alarmVolumeMuted) {
            titleBlock.addView(
                TextView(this).apply {
                    text = "Alarm volume is muted or too low. Raise alarm volume to hear speech and tone."
                    textSize = 15f
                    typeface = Typeface.DEFAULT_BOLD
                    setTextColor(destructive)
                    gravity = Gravity.CENTER
                    setPadding(dp(14), dp(16), dp(14), 0)
                    setLineSpacing(dp(2).toFloat(), 1.0f)
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
            alarmButton("Acknowledge", bone, ink, 24) { acknowledge() },
            LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                dp(58),
            ).apply { topMargin = dp(24) },
        )
        content.addView(
            alarmButton("Snooze $snoozeMinutes min", surfaceGlass, bone, 24, line, 1) { snooze() },
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
                setTextColor(boneDim)
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

    private fun verticalGradient(colors: IntArray, radiusPx: Int): GradientDrawable {
        return GradientDrawable(GradientDrawable.Orientation.TL_BR, colors).apply {
            cornerRadius = radiusPx.toFloat()
        }
    }

    private fun auraBackground(aura: Int): GradientDrawable {
        return GradientDrawable().apply {
            shape = GradientDrawable.RECTANGLE
            gradientType = GradientDrawable.RADIAL_GRADIENT
            colors = intArrayOf(
                Color.argb(150, Color.red(aura), Color.green(aura), Color.blue(aura)),
                Color.argb(48, Color.red(aura), Color.green(aura), Color.blue(aura)),
                Color.rgb(11, 12, 16),
            )
            gradientRadius = dp(430).toFloat()
            setGradientCenter(0.5f, 0.32f)
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
