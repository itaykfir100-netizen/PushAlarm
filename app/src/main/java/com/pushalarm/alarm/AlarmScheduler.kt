package com.pushalarm.alarm

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import com.pushalarm.data.Alarm
import java.util.Calendar

object AlarmScheduler {

    fun schedule(context: Context, alarm: Alarm) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

        if (alarm.repeatDays == 0) {
            // One-time alarm: schedule for next occurrence
            val triggerAt = nextTriggerTime(alarm.hour, alarm.minute, -1)
            val pi = buildPendingIntent(context, alarm, -1)
            alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pi)
        } else {
            // Repeating: schedule one PendingIntent per enabled day
            for (dayIndex in 0..6) {
                if (alarm.isDayEnabled(dayIndex)) {
                    val triggerAt = nextTriggerTime(alarm.hour, alarm.minute, dayIndex)
                    val pi = buildPendingIntent(context, alarm, dayIndex)
                    alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pi)
                }
            }
        }
    }

    fun cancel(context: Context, alarm: Alarm) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        if (alarm.repeatDays == 0) {
            alarmManager.cancel(buildPendingIntent(context, alarm, -1))
        } else {
            for (dayIndex in 0..6) {
                alarmManager.cancel(buildPendingIntent(context, alarm, dayIndex))
            }
        }
    }

    fun rescheduleAfterFire(context: Context, alarm: Alarm, dayIndex: Int) {
        if (!alarm.isEnabled || alarm.repeatDays == 0) return
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val triggerAt = nextTriggerTime(alarm.hour, alarm.minute, dayIndex) + 7 * 24 * 60 * 60 * 1000L
        val pi = buildPendingIntent(context, alarm, dayIndex)
        alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pi)
    }

    private fun nextTriggerTime(hour: Int, minute: Int, dayOfWeekIndex: Int): Long {
        val cal = Calendar.getInstance()
        cal.set(Calendar.HOUR_OF_DAY, hour)
        cal.set(Calendar.MINUTE, minute)
        cal.set(Calendar.SECOND, 0)
        cal.set(Calendar.MILLISECOND, 0)

        if (dayOfWeekIndex >= 0) {
            // dayIndex: 0=Mon..6=Sun → Calendar day: Mon=2..Sun=1
            val calDay = when (dayOfWeekIndex) {
                0 -> Calendar.MONDAY
                1 -> Calendar.TUESDAY
                2 -> Calendar.WEDNESDAY
                3 -> Calendar.THURSDAY
                4 -> Calendar.FRIDAY
                5 -> Calendar.SATURDAY
                else -> Calendar.SUNDAY
            }
            cal.set(Calendar.DAY_OF_WEEK, calDay)
            if (cal.timeInMillis <= System.currentTimeMillis()) {
                cal.add(Calendar.WEEK_OF_YEAR, 1)
            }
        } else {
            if (cal.timeInMillis <= System.currentTimeMillis()) {
                cal.add(Calendar.DAY_OF_YEAR, 1)
            }
        }
        return cal.timeInMillis
    }

    private fun buildPendingIntent(context: Context, alarm: Alarm, dayIndex: Int): PendingIntent {
        val intent = Intent(context, AlarmReceiver::class.java).apply {
            putExtra(EXTRA_ALARM_ID, alarm.id)
            putExtra(EXTRA_ALARM_LABEL, alarm.label)
            putExtra(EXTRA_PUSH_UP_COUNT, alarm.pushUpCount)
            putExtra(EXTRA_DAY_INDEX, dayIndex)
        }
        // Unique request code per alarm+day combination
        val requestCode = (alarm.id * 10 + (dayIndex + 1)).toInt()
        return PendingIntent.getBroadcast(
            context, requestCode, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    const val EXTRA_ALARM_ID = "alarm_id"
    const val EXTRA_ALARM_LABEL = "alarm_label"
    const val EXTRA_PUSH_UP_COUNT = "push_up_count"
    const val EXTRA_DAY_INDEX = "day_index"
}
