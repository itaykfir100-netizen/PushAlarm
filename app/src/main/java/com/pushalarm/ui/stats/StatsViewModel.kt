package com.pushalarm.ui.stats

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.pushalarm.PushAlarmApp
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import java.util.*

data class StatsState(
    val totalPushUps: Int = 0,
    val currentStreak: Int = 0,
    val bestStreak: Int = 0,
    val avgPerDay: Float = 0f,
    val weeklyData: List<Pair<String, Int>> = emptyList(), // day label → reps
    val totalSessions: Int = 0,
)

class StatsViewModel(application: Application) : AndroidViewModel(application) {

    private val db = (application as PushAlarmApp).database

    private val _stats = MutableStateFlow(StatsState())
    val stats = _stats.asStateFlow()

    init {
        viewModelScope.launch {
            db.workoutLogDao().getTotalPushUps().collect { total ->
                computeStats(total ?: 0)
            }
        }
    }

    private suspend fun computeStats(totalPushUps: Int) {
        val logs = db.workoutLogDao().getCompletedLogs()
        val streak = computeStreak(logs.map { it.completedAt })
        val bestStreak = computeBestStreak(logs.map { it.completedAt })
        val avgPerDay = if (logs.isEmpty()) 0f else {
            val uniqueDays = logs.map { dayKey(it.completedAt) }.toSet().size
            if (uniqueDays > 0) totalPushUps.toFloat() / uniqueDays else 0f
        }
        val weekly = computeWeeklyData()

        _stats.value = StatsState(
            totalPushUps = totalPushUps,
            currentStreak = streak,
            bestStreak = bestStreak,
            avgPerDay = avgPerDay,
            weeklyData = weekly,
            totalSessions = logs.size,
        )
    }

    private fun dayKey(ms: Long): String {
        val cal = Calendar.getInstance().apply { timeInMillis = ms }
        return "${cal.get(Calendar.YEAR)}-${cal.get(Calendar.DAY_OF_YEAR)}"
    }

    private fun computeStreak(timestamps: List<Long>): Int {
        if (timestamps.isEmpty()) return 0
        val days = timestamps.map { dayKey(it) }.toSortedSet().reversed()
        val todayKey = dayKey(System.currentTimeMillis())
        var streak = 0
        val cal = Calendar.getInstance()
        var expectedKey = todayKey
        for (day in days) {
            if (day == expectedKey) {
                streak++
                cal.add(Calendar.DAY_OF_YEAR, -1)
                expectedKey = dayKey(cal.timeInMillis)
            } else break
        }
        return streak
    }

    private fun computeBestStreak(timestamps: List<Long>): Int {
        if (timestamps.isEmpty()) return 0
        val days = timestamps.map { dayKey(it) }.toSortedSet().toList()
        var best = 1; var current = 1
        val cal = Calendar.getInstance()
        for (i in 1 until days.size) {
            cal.timeInMillis = System.currentTimeMillis()
            val prev = days[i - 1]
            val curr = days[i]
            // Check if consecutive
            current = if (areConsecutiveDays(prev, curr)) current + 1 else 1
            if (current > best) best = current
        }
        return best
    }

    private fun areConsecutiveDays(day1: String, day2: String): Boolean {
        val (y1, d1) = day1.split("-").map { it.toInt() }
        val (y2, d2) = day2.split("-").map { it.toInt() }
        if (y1 == y2) return d2 - d1 == 1
        if (y2 - y1 == 1) {
            val cal = Calendar.getInstance()
            cal.set(Calendar.YEAR, y1)
            val maxDay = cal.getActualMaximum(Calendar.DAY_OF_YEAR)
            return d1 == maxDay && d2 == 1
        }
        return false
    }

    private suspend fun computeWeeklyData(): List<Pair<String, Int>> {
        val cal = Calendar.getInstance()
        val result = mutableListOf<Pair<String, Int>>()
        val dayLabels = listOf("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun")

        // Go back to Monday of current week
        val dow = cal.get(Calendar.DAY_OF_WEEK)
        val daysFromMon = (dow - Calendar.MONDAY + 7) % 7
        cal.add(Calendar.DAY_OF_YEAR, -daysFromMon)

        for (i in 0..6) {
            val start = startOfDay(cal)
            val end = start + 24 * 60 * 60 * 1000L
            val reps = db.workoutLogDao().getPushUpsForDay(start, end) ?: 0
            result.add(Pair(dayLabels[i], reps))
            cal.add(Calendar.DAY_OF_YEAR, 1)
        }
        return result
    }

    private fun startOfDay(cal: Calendar): Long {
        val c = cal.clone() as Calendar
        c.set(Calendar.HOUR_OF_DAY, 0)
        c.set(Calendar.MINUTE, 0)
        c.set(Calendar.SECOND, 0)
        c.set(Calendar.MILLISECOND, 0)
        return c.timeInMillis
    }
}
