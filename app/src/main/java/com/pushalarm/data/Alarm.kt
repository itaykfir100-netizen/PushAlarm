package com.pushalarm.data

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "alarms")
data class Alarm(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val hour: Int,
    val minute: Int,
    val label: String = "",
    val pushUpCount: Int = 10,
    val isEnabled: Boolean = true,
    // Days encoded as bitmask: bit 0=Mon, 1=Tue, 2=Wed, 3=Thu, 4=Fri, 5=Sat, 6=Sun
    val repeatDays: Int = 0b0111110, // Mon-Fri by default
) {
    fun isDayEnabled(dayIndex: Int): Boolean = (repeatDays shr dayIndex) and 1 == 1

    fun withDayToggled(dayIndex: Int): Alarm {
        val newDays = repeatDays xor (1 shl dayIndex)
        return copy(repeatDays = newDays)
    }

    fun formattedTime(): String {
        val h = if (hour % 12 == 0) 12 else hour % 12
        val m = minute.toString().padStart(2, '0')
        val amPm = if (hour < 12) "AM" else "PM"
        return "$h:$m $amPm"
    }
}
