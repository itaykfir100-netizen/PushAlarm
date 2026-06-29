package com.example.alarmlock

import android.app.AlarmManager
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.alarmlock/alarm"
    private var channel: MethodChannel? = null
    private var pendingAlarmId: Int? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        channel!!.setMethodCallHandler { call, result ->
            when (call.method) {
                "scheduleAlarm" -> {
                    scheduleAlarm(call.argument<Int>("id")!!, call.argument<Long>("fireTimeMs")!!)
                    result.success(null)
                }
                "cancelAlarm" -> {
                    cancelAlarmNative(call.argument<Int>("id")!!)
                    result.success(null)
                }
                "stopAlarmService" -> {
                    stopAlarmService()
                    result.success(null)
                }
                "getActiveAlarmId" -> {
                    val id = getSharedPreferences("AlarmPrefs", Context.MODE_PRIVATE)
                        .getInt("active_alarm_id", -1)
                    result.success(if (id < 0) null else id)
                }
                "getPendingAlarmId" -> {
                    result.success(pendingAlarmId)
                    pendingAlarmId = null
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val id = intent?.getIntExtra("alarm_id", -1) ?: -1
        if (id >= 0) pendingAlarmId = id
    }

    // Called when notification is tapped while app is already running / in background.
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        val id = intent.getIntExtra("alarm_id", -1)
        if (id < 0) return
        pendingAlarmId = id
        // Flutter is already running at this point — invoke directly.
        channel?.invokeMethod("alarmFired", id)
    }

    private fun scheduleAlarm(id: Int, fireTimeMs: Long) {
        val am = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pi = alarmPi(id)
        am.setAlarmClock(AlarmManager.AlarmClockInfo(fireTimeMs, pi), pi)
    }

    private fun cancelAlarmNative(id: Int) {
        (getSystemService(Context.ALARM_SERVICE) as AlarmManager).cancel(alarmPi(id))
        val prefs = getSharedPreferences("AlarmPrefs", Context.MODE_PRIVATE)
        if (prefs.getInt("active_alarm_id", -1) == id) stopAlarmService()
    }

    private fun stopAlarmService() {
        val prefs = getSharedPreferences("AlarmPrefs", Context.MODE_PRIVATE)
        val id = prefs.getInt("active_alarm_id", -1)
        stopService(Intent(this, AlarmForegroundService::class.java))
        if (id >= 0) {
            (getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager)
                .cancel(AlarmForegroundService.NOTIF_ID)
        }
        prefs.edit().remove("active_alarm_id").apply()
    }

    private fun alarmPi(id: Int): PendingIntent {
        val i = Intent(this, AlarmReceiver::class.java).putExtra("alarm_id", id)
        return PendingIntent.getBroadcast(
            this, id, i,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }
}
