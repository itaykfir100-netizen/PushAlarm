package com.pushalarm.data

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "workout_logs")
data class WorkoutLog(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val alarmId: Long,
    val completedAt: Long = System.currentTimeMillis(),
    val pushUpsDone: Int,
    val targetPushUps: Int,
    val completed: Boolean,
)
