package com.pushalarm.alarm

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.content.ContextCompat
import com.pushalarm.PushAlarmApp
import com.pushalarm.data.Alarm
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED -> rescheduleAllAlarms(context)
            else -> fireAlarm(context, intent)
        }
    }

    private fun fireAlarm(context: Context, intent: Intent) {
        val alarmId = intent.getLongExtra(AlarmScheduler.EXTRA_ALARM_ID, -1L)
        val label = intent.getStringExtra(AlarmScheduler.EXTRA_ALARM_LABEL) ?: ""
        val pushUpCount = intent.getIntExtra(AlarmScheduler.EXTRA_PUSH_UP_COUNT, 10)
        val dayIndex = intent.getIntExtra(AlarmScheduler.EXTRA_DAY_INDEX, -1)

        val serviceIntent = Intent(context, AlarmService::class.java).apply {
            putExtra(AlarmScheduler.EXTRA_ALARM_ID, alarmId)
            putExtra(AlarmScheduler.EXTRA_ALARM_LABEL, label)
            putExtra(AlarmScheduler.EXTRA_PUSH_UP_COUNT, pushUpCount)
            putExtra(AlarmScheduler.EXTRA_DAY_INDEX, dayIndex)
        }
        ContextCompat.startForegroundService(context, serviceIntent)

        // Reschedule the alarm for next week if it's a repeating alarm
        if (dayIndex >= 0) {
            CoroutineScope(Dispatchers.IO).launch {
                val db = (context.applicationContext as PushAlarmApp).database
                val alarm = db.alarmDao().getAlarmById(alarmId) ?: return@launch
                AlarmScheduler.rescheduleAfterFire(context, alarm, dayIndex)
            }
        }
    }

    private fun rescheduleAllAlarms(context: Context) {
        CoroutineScope(Dispatchers.IO).launch {
            val db = (context.applicationContext as PushAlarmApp).database
            val alarms = db.alarmDao().getEnabledAlarms()
            alarms.forEach { alarm ->
                AlarmScheduler.schedule(context, alarm)
            }
        }
    }
}
