package com.pushalarm

import android.app.Application
import com.pushalarm.data.AppDatabase

class PushAlarmApp : Application() {
    val database: AppDatabase by lazy { AppDatabase.getInstance(this) }
}
