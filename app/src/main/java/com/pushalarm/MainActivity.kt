package com.pushalarm

import android.Manifest
import android.app.AlarmManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Alarm
import androidx.compose.material.icons.filled.BarChart
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.core.content.ContextCompat
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavType
import androidx.navigation.compose.*
import androidx.navigation.navArgument
import com.pushalarm.ui.alarms.AlarmsScreen
import com.pushalarm.ui.alarms.AlarmsViewModel
import com.pushalarm.ui.alarms.SetAlarmScreen
import com.pushalarm.ui.alarms.SetAlarmViewModel
import com.pushalarm.ui.stats.StatsScreen
import com.pushalarm.ui.stats.StatsViewModel
import com.pushalarm.ui.theme.*

class MainActivity : ComponentActivity() {

    private val permissionsLauncher = registerForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions()
    ) { /* handle permissions */ }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        requestPermissions()

        setContent {
            PushAlarmTheme {
                AppNavigation()
            }
        }
    }

    private fun requestPermissions() {
        val needed = mutableListOf(Manifest.permission.CAMERA)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            needed.add(Manifest.permission.POST_NOTIFICATIONS)
        }
        val toRequest = needed.filter {
            ContextCompat.checkSelfPermission(this, it) != PackageManager.PERMISSION_GRANTED
        }
        if (toRequest.isNotEmpty()) permissionsLauncher.launch(toRequest.toTypedArray())

        // Exact alarm permission
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val am = getSystemService(Context.ALARM_SERVICE) as AlarmManager
            if (!am.canScheduleExactAlarms()) {
                startActivity(Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM).apply {
                    data = Uri.parse("package:$packageName")
                })
            }
        }
    }
}

@Composable
private fun AppNavigation() {
    val navController = rememberNavController()

    Scaffold(
        containerColor = BackgroundDark,
        bottomBar = {
            NavigationBar(
                containerColor = Color(0xFF111111),
                tonalElevation = 0.dp,
            ) {
                val currentRoute = navController.currentBackStackEntryAsState().value?.destination?.route

                NavigationBarItem(
                    selected = currentRoute == "alarms",
                    onClick = { navController.navigate("alarms") { launchSingleTop = true } },
                    icon = { Icon(Icons.Default.Alarm, contentDescription = "Alarms") },
                    label = { Text("Alarms") },
                    colors = NavigationBarItemDefaults.colors(
                        selectedIconColor = GreenAccent,
                        selectedTextColor = GreenAccent,
                        unselectedIconColor = TextSecondary,
                        unselectedTextColor = TextSecondary,
                        indicatorColor = GreenAccent.copy(alpha = 0.12f),
                    )
                )
                NavigationBarItem(
                    selected = currentRoute == "stats",
                    onClick = { navController.navigate("stats") { launchSingleTop = true } },
                    icon = { Icon(Icons.Default.BarChart, contentDescription = "Stats") },
                    label = { Text("Stats") },
                    colors = NavigationBarItemDefaults.colors(
                        selectedIconColor = GreenAccent,
                        selectedTextColor = GreenAccent,
                        unselectedIconColor = TextSecondary,
                        unselectedTextColor = TextSecondary,
                        indicatorColor = GreenAccent.copy(alpha = 0.12f),
                    )
                )
            }
        }
    ) { paddingValues ->
        NavHost(
            navController = navController,
            startDestination = "alarms",
            modifier = Modifier.padding(paddingValues),
        ) {
            composable("alarms") {
                val vm: AlarmsViewModel = viewModel()
                AlarmsScreen(
                    viewModel = vm,
                    onAddAlarm = { navController.navigate("set_alarm/-1") },
                    onEditAlarm = { id -> navController.navigate("set_alarm/$id") },
                )
            }
            composable(
                route = "set_alarm/{alarmId}",
                arguments = listOf(navArgument("alarmId") { type = NavType.LongType }),
            ) { backStack ->
                val id = backStack.arguments?.getLong("alarmId") ?: -1L
                val vm: SetAlarmViewModel = viewModel()
                SetAlarmScreen(
                    viewModel = vm,
                    alarmId = id,
                    onBack = { navController.popBackStack() },
                )
            }
            composable("stats") {
                val vm: StatsViewModel = viewModel()
                StatsScreen(viewModel = vm)
            }
        }
    }
}
