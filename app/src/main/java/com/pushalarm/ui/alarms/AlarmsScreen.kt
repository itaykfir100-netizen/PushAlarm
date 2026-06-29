package com.pushalarm.ui.alarms

import androidx.compose.animation.animateColorAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.pushalarm.data.Alarm
import com.pushalarm.ui.theme.*
import java.text.SimpleDateFormat
import java.util.*

private val DAY_LABELS = listOf("M", "T", "W", "Th", "F", "Sa", "Su")

@Composable
fun AlarmsScreen(
    viewModel: AlarmsViewModel,
    onAddAlarm: () -> Unit,
    onEditAlarm: (Long) -> Unit,
) {
    val alarms by viewModel.alarms.collectAsState()
    val context = LocalContext.current
    val today = remember {
        SimpleDateFormat("EEEE, MMM d", Locale.getDefault()).format(Date()).uppercase()
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(BackgroundDark)
    ) {
        Column(modifier = Modifier.fillMaxSize()) {
            // Header
            Column(modifier = Modifier.padding(horizontal = 20.dp, vertical = 16.dp)) {
                Text(
                    text = today,
                    color = TextSecondary,
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Medium,
                    letterSpacing = 1.sp,
                )
                Text(
                    text = "Alarms",
                    color = TextPrimary,
                    fontWeight = FontWeight.Bold,
                    fontSize = 34.sp,
                )
            }

            if (alarms.isEmpty()) {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Text("No alarms yet", color = TextSecondary, fontSize = 18.sp)
                        Spacer(Modifier.height(8.dp))
                        Text("Tap + to create one", color = TextSecondary.copy(alpha = 0.6f), fontSize = 14.sp)
                    }
                }
            } else {
                LazyColumn(
                    modifier = Modifier.weight(1f),
                    contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    items(alarms, key = { it.id }) { alarm ->
                        AlarmCard(
                            alarm = alarm,
                            onToggle = { viewModel.toggleAlarm(alarm, context) },
                            onEdit = { onEditAlarm(alarm.id) },
                        )
                    }
                    item {
                        // Simulate button at bottom
                        if (alarms.isNotEmpty()) {
                            Spacer(Modifier.height(8.dp))
                            OutlinedButton(
                                onClick = { viewModel.simulateAlarm(alarms.first(), context) },
                                modifier = Modifier.fillMaxWidth(),
                                colors = ButtonDefaults.outlinedButtonColors(
                                    contentColor = RedAccent,
                                ),
                                border = androidx.compose.foundation.BorderStroke(1.dp, RedAccent.copy(alpha = 0.5f)),
                                shape = RoundedCornerShape(12.dp),
                            ) {
                                Text(
                                    "Simulate Alarm Firing →",
                                    color = RedAccent,
                                    fontWeight = FontWeight.SemiBold,
                                )
                            }
                        }
                    }
                }
            }
        }

        // FAB
        FloatingActionButton(
            onClick = onAddAlarm,
            modifier = Modifier
                .align(Alignment.TopEnd)
                .padding(top = 18.dp, end = 16.dp),
            containerColor = GreenAccent,
            contentColor = BackgroundDark,
            shape = RoundedCornerShape(24.dp),
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.padding(horizontal = 16.dp)
            ) {
                Icon(Icons.Default.Add, contentDescription = "Add", modifier = Modifier.size(20.dp))
                Spacer(Modifier.width(4.dp))
                Text("New", fontWeight = FontWeight.Bold, fontSize = 15.sp)
            }
        }
    }
}

@Composable
private fun AlarmCard(
    alarm: Alarm,
    onToggle: () -> Unit,
    onEdit: () -> Unit,
) {
    val alpha = if (alarm.isEnabled) 1f else 0.45f

    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { onEdit() },
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = CardDark),
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.Top,
            ) {
                // Time + label
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = buildString {
                            val h = if (alarm.hour % 12 == 0) 12 else alarm.hour % 12
                            val m = alarm.minute.toString().padStart(2, '0')
                            append("$h:$m")
                        },
                        color = TextPrimary.copy(alpha = alpha),
                        fontWeight = FontWeight.Bold,
                        fontSize = 52.sp,
                        lineHeight = 52.sp,
                    )
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text(
                            text = buildString {
                                append(if (alarm.hour < 12) "AM" else "PM")
                                if (alarm.label.isNotEmpty()) append("  ${alarm.label}")
                            },
                            color = TextSecondary.copy(alpha = alpha),
                            fontSize = 15.sp,
                        )
                    }
                }

                // Toggle + reps badge
                Column(horizontalAlignment = Alignment.End) {
                    Switch(
                        checked = alarm.isEnabled,
                        onCheckedChange = { onToggle() },
                        colors = SwitchDefaults.colors(
                            checkedThumbColor = Color.White,
                            checkedTrackColor = GreenAccent,
                            uncheckedThumbColor = Color.Gray,
                            uncheckedTrackColor = SurfaceDark,
                        )
                    )
                    Spacer(Modifier.height(4.dp))
                    Box(
                        modifier = Modifier
                            .clip(RoundedCornerShape(8.dp))
                            .background(GreenAccent.copy(alpha = if (alarm.isEnabled) 0.15f else 0.05f))
                            .padding(horizontal = 10.dp, vertical = 4.dp)
                    ) {
                        Text(
                            text = "${alarm.pushUpCount} reps",
                            color = GreenAccent.copy(alpha = alpha),
                            fontWeight = FontWeight.SemiBold,
                            fontSize = 13.sp,
                        )
                    }
                }
            }

            Spacer(Modifier.height(10.dp))

            // Day chips
            Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                DAY_LABELS.forEachIndexed { index, label ->
                    val isActive = alarm.isDayEnabled(index)
                    DayChip(label = label, isActive = isActive && alarm.isEnabled)
                }
            }
        }
    }
}

@Composable
private fun DayChip(label: String, isActive: Boolean) {
    val bgColor by animateColorAsState(
        targetValue = if (isActive) GreenAccent else DayInactive,
        label = "dayChipBg"
    )
    val textColor by animateColorAsState(
        targetValue = if (isActive) BackgroundDark else TextSecondary,
        label = "dayChipText"
    )
    Box(
        modifier = Modifier
            .size(width = 30.dp, height = 28.dp)
            .clip(RoundedCornerShape(6.dp))
            .background(bgColor),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = label,
            color = textColor,
            fontSize = 11.sp,
            fontWeight = FontWeight.SemiBold,
        )
    }
}
