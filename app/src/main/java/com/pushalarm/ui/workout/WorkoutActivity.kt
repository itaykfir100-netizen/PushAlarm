package com.pushalarm.ui.workout

import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.viewModels
import androidx.compose.runtime.Composable
import com.pushalarm.alarm.AlarmScheduler
import com.pushalarm.alarm.AlarmService
import com.pushalarm.ui.theme.PushAlarmTheme

class WorkoutActivity : ComponentActivity() {

    private val viewModel: WorkoutViewModel by viewModels()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Show on lock screen and keep screen on
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                    WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
            )
        }

        val alarmId = intent.getLongExtra(AlarmScheduler.EXTRA_ALARM_ID, -1L)
        val label = intent.getStringExtra(AlarmScheduler.EXTRA_ALARM_LABEL) ?: ""
        val pushUpCount = intent.getIntExtra(AlarmScheduler.EXTRA_PUSH_UP_COUNT, 10)

        setContent {
            PushAlarmTheme {
                WorkoutScreen(
                    viewModel = viewModel,
                    alarmId = alarmId,
                    targetReps = pushUpCount,
                    alarmLabel = label,
                    onDismiss = ::finish,
                )
            }
        }
    }

    override fun finish() {
        stopAlarmService()
        super.finish()
    }

    private fun stopAlarmService() {
        val intent = Intent(this, AlarmService::class.java)
        stopService(intent)
    }
}
