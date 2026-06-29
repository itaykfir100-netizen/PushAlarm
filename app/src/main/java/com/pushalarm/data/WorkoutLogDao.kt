package com.pushalarm.data

import androidx.room.*
import kotlinx.coroutines.flow.Flow

@Dao
interface WorkoutLogDao {
    @Query("SELECT * FROM workout_logs ORDER BY completedAt DESC")
    fun getAllLogs(): Flow<List<WorkoutLog>>

    @Query("SELECT SUM(pushUpsDone) FROM workout_logs WHERE completed = 1")
    fun getTotalPushUps(): Flow<Int?>

    @Query("SELECT * FROM workout_logs WHERE completed = 1 ORDER BY completedAt DESC")
    suspend fun getCompletedLogs(): List<WorkoutLog>

    @Query("""
        SELECT SUM(pushUpsDone) FROM workout_logs
        WHERE completed = 1
        AND completedAt >= :startOfDay
        AND completedAt < :endOfDay
    """)
    suspend fun getPushUpsForDay(startOfDay: Long, endOfDay: Long): Int?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(log: WorkoutLog): Long
}
