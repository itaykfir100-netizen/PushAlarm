package com.pushalarm.ui.workout

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.google.mlkit.vision.pose.Pose
import com.pushalarm.PushAlarmApp
import com.pushalarm.data.WorkoutLog
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

class WorkoutViewModel(application: Application) : AndroidViewModel(application) {

    private val db = (application as PushAlarmApp).database
    private val counter = PushUpCounter()

    private val _repCount = MutableStateFlow(0)
    val repCount = _repCount.asStateFlow()

    private val _targetReps = MutableStateFlow(10)
    val targetReps = _targetReps.asStateFlow()

    private val _isComplete = MutableStateFlow(false)
    val isComplete = _isComplete.asStateFlow()

    private val _currentPose = MutableStateFlow<Pose?>(null)
    val currentPose = _currentPose.asStateFlow()

    private val _elapsedSeconds = MutableStateFlow(0)
    val elapsedSeconds = _elapsedSeconds.asStateFlow()

    private var alarmId: Long = -1L

    init {
        viewModelScope.launch {
            while (true) {
                delay(1000)
                if (!_isComplete.value) _elapsedSeconds.value++
            }
        }
    }

    fun init(alarmId: Long, targetReps: Int) {
        this.alarmId = alarmId
        _targetReps.value = targetReps
        counter.reset()
        _repCount.value = 0
        _isComplete.value = false
        _elapsedSeconds.value = 0
    }

    fun onPoseDetected(pose: Pose) {
        _currentPose.value = pose
        if (_isComplete.value) return
        val newCount = counter.process(pose)
        _repCount.value = newCount
        if (newCount >= _targetReps.value) {
            _isComplete.value = true
            saveWorkoutLog(completed = true)
        }
    }

    fun skipWorkout() {
        _isComplete.value = true
        saveWorkoutLog(completed = false)
    }

    private fun saveWorkoutLog(completed: Boolean) {
        viewModelScope.launch {
            db.workoutLogDao().insert(
                WorkoutLog(
                    alarmId = alarmId,
                    pushUpsDone = _repCount.value,
                    targetPushUps = _targetReps.value,
                    completed = completed,
                )
            )
        }
    }
}
