package com.pushalarm.ui.workout

import com.google.mlkit.vision.pose.Pose
import com.google.mlkit.vision.pose.PoseLandmark
import kotlin.math.abs
import kotlin.math.atan2

class PushUpCounter {

    enum class State { UNKNOWN, UP, DOWN }

    private var state = State.UNKNOWN
    var repCount = 0
        private set

    fun process(pose: Pose): Int {
        val leftShoulder = pose.getPoseLandmark(PoseLandmark.LEFT_SHOULDER) ?: return repCount
        val leftElbow = pose.getPoseLandmark(PoseLandmark.LEFT_ELBOW) ?: return repCount
        val leftWrist = pose.getPoseLandmark(PoseLandmark.LEFT_WRIST) ?: return repCount
        val rightShoulder = pose.getPoseLandmark(PoseLandmark.RIGHT_SHOULDER) ?: return repCount
        val rightElbow = pose.getPoseLandmark(PoseLandmark.RIGHT_ELBOW) ?: return repCount
        val rightWrist = pose.getPoseLandmark(PoseLandmark.RIGHT_WRIST) ?: return repCount

        val minConfidence = 0.5f
        if (leftShoulder.inFrameLikelihood < minConfidence ||
            leftElbow.inFrameLikelihood < minConfidence ||
            rightShoulder.inFrameLikelihood < minConfidence ||
            rightElbow.inFrameLikelihood < minConfidence
        ) return repCount

        val leftAngle = calculateAngle(leftShoulder, leftElbow, leftWrist)
        val rightAngle = calculateAngle(rightShoulder, rightElbow, rightWrist)
        val avgAngle = (leftAngle + rightAngle) / 2.0

        val newState = when {
            avgAngle < 90.0 -> State.DOWN
            avgAngle > 155.0 -> State.UP
            else -> state
        }

        if (state == State.DOWN && newState == State.UP) {
            repCount++
        }
        state = newState
        return repCount
    }

    fun reset() {
        state = State.UNKNOWN
        repCount = 0
    }

    private fun calculateAngle(
        a: PoseLandmark,
        b: PoseLandmark, // vertex
        c: PoseLandmark,
    ): Double {
        val ax = a.position.x.toDouble()
        val ay = a.position.y.toDouble()
        val bx = b.position.x.toDouble()
        val by = b.position.y.toDouble()
        val cx = c.position.x.toDouble()
        val cy = c.position.y.toDouble()

        val angle1 = atan2(ay - by, ax - bx)
        val angle2 = atan2(cy - by, cx - bx)
        var angle = Math.toDegrees(abs(angle1 - angle2))
        if (angle > 180) angle = 360 - angle
        return angle
    }
}
