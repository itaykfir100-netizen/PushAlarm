package com.pushalarm.ui.alarms

import android.app.Application
import android.content.Context
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.pushalarm.PushAlarmApp
import com.pushalarm.alarm.AlarmScheduler
import com.pushalarm.data.Alarm
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import java.util.Calendar

class SetAlarmViewModel(application: Application) : AndroidViewModel(application) {

    private val db = (application as PushAlarmApp).database
    private val dao = db.alarmDao()

    private val _alarm = MutableStateFlow(defaultAlarm())
    val alarm = _alarm.asStateFlow()

    private val _saved = MutableStateFlow(false)
    val saved = _saved.asStateFlow()

    fun loadAlarm(id: Long) {
        if (id <= 0L) return
        viewModelScope.launch {
            dao.getAlarmById(id)?.let { _alarm.value = it }
        }
    }

    fun setHour(hour: Int) { _alarm.value = _alarm.value.copy(hour = hour) }
    fun setMinute(minute: Int) { _alarm.value = _alarm.value.copy(minute = minute) }
    fun setLabel(label: String) { _alarm.value = _alarm.value.copy(label = label) }
    fun setPushUpCount(count: Int) { _alarm.value = _alarm.value.copy(pushUpCount = count) }
    fun toggleDay(dayIndex: Int) { _alarm.value = _alarm.value.withDayToggled(dayIndex) }

    fun save(context: Context) {
        viewModelScope.launch {
            val alarm = _alarm.value
            val savedId = dao.insert(alarm)
            val savedAlarm = alarm.copy(id = savedId)
            if (savedAlarm.isEnabled) {
                AlarmScheduler.schedule(context, savedAlarm)
            }
            _saved.value = true
        }
    }

    private fun defaultAlarm(): Alarm {
        val cal = Calendar.getInstance()
        cal.add(Calendar.HOUR_OF_DAY, 1)
        return Alarm(
            hour = cal.get(Calendar.HOUR_OF_DAY),
            minute = 0,
            pushUpCount = 10,
            repeatDays = 0b0111110,
        )
    }
}
