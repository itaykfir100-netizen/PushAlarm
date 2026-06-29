package com.pushalarm.ui.alarms

import android.app.Application
import android.content.Context
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.pushalarm.PushAlarmApp
import com.pushalarm.alarm.AlarmScheduler
import com.pushalarm.data.Alarm
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

class AlarmsViewModel(application: Application) : AndroidViewModel(application) {

    private val db = (application as PushAlarmApp).database
    private val dao = db.alarmDao()

    val alarms = dao.getAllAlarms().stateIn(
        viewModelScope,
        SharingStarted.WhileSubscribed(5000),
        emptyList()
    )

    fun toggleAlarm(alarm: Alarm, context: Context) {
        viewModelScope.launch {
            val updated = alarm.copy(isEnabled = !alarm.isEnabled)
            dao.update(updated)
            if (updated.isEnabled) {
                AlarmScheduler.schedule(context, updated)
            } else {
                AlarmScheduler.cancel(context, updated)
            }
        }
    }

    fun deleteAlarm(alarm: Alarm, context: Context) {
        viewModelScope.launch {
            AlarmScheduler.cancel(context, alarm)
            dao.delete(alarm)
        }
    }

    fun simulateAlarm(alarm: Alarm, context: Context) {
        AlarmScheduler.cancel(context, alarm)
        val simulateIntent = android.content.Intent(context, com.pushalarm.alarm.AlarmReceiver::class.java).apply {
            putExtra(AlarmScheduler.EXTRA_ALARM_ID, alarm.id)
            putExtra(AlarmScheduler.EXTRA_ALARM_LABEL, alarm.label)
            putExtra(AlarmScheduler.EXTRA_PUSH_UP_COUNT, alarm.pushUpCount)
            putExtra(AlarmScheduler.EXTRA_DAY_INDEX, -1)
        }
        context.sendBroadcast(simulateIntent)
    }
}
