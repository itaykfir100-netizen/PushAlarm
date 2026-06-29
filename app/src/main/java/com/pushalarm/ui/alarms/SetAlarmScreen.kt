package com.pushalarm.ui.alarms

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Remove
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
import com.pushalarm.ui.theme.*

private val DAY_LABELS = listOf("M", "T", "W", "Th", "F", "Sa", "Su")

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SetAlarmScreen(
    viewModel: SetAlarmViewModel,
    alarmId: Long = -1L,
    onBack: () -> Unit,
) {
    val context = LocalContext.current
    val alarm by viewModel.alarm.collectAsState()
    val saved by viewModel.saved.collectAsState()

    LaunchedEffect(alarmId) { viewModel.loadAlarm(alarmId) }
    LaunchedEffect(saved) { if (saved) onBack() }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(BackgroundDark)
    ) {
        // Top bar
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 8.dp, vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween,
        ) {
            IconButton(onClick = onBack) {
                Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back", tint = GreenAccent)
            }
            Text(
                text = if (alarmId <= 0) "New Alarm" else "Edit Alarm",
                color = TextPrimary,
                fontWeight = FontWeight.Bold,
                fontSize = 18.sp,
            )
            TextButton(onClick = { viewModel.save(context) }) {
                Text("Save", color = GreenAccent, fontWeight = FontWeight.Bold, fontSize = 16.sp)
            }
        }

        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 20.dp),
            verticalArrangement = Arrangement.spacedBy(20.dp),
        ) {
            Spacer(Modifier.height(8.dp))

            // Time Picker
            TimePickerSection(
                hour = alarm.hour,
                minute = alarm.minute,
                onHourChange = viewModel::setHour,
                onMinuteChange = viewModel::setMinute,
            )

            // Label
            SectionCard(title = "Label") {
                OutlinedTextField(
                    value = alarm.label,
                    onValueChange = viewModel::setLabel,
                    placeholder = { Text("e.g. Morning Grind", color = TextSecondary) },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true,
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = GreenAccent,
                        unfocusedBorderColor = SurfaceDark,
                        focusedTextColor = TextPrimary,
                        unfocusedTextColor = TextPrimary,
                        cursorColor = GreenAccent,
                    ),
                    shape = RoundedCornerShape(12.dp),
                )
            }

            // Repeat Days
            SectionCard(title = "Repeat") {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                ) {
                    DAY_LABELS.forEachIndexed { index, label ->
                        val isActive = alarm.isDayEnabled(index)
                        Box(
                            modifier = Modifier
                                .size(40.dp)
                                .clip(RoundedCornerShape(10.dp))
                                .background(if (isActive) GreenAccent else SurfaceDark)
                                .clickable { viewModel.toggleDay(index) },
                            contentAlignment = Alignment.Center,
                        ) {
                            Text(
                                text = label,
                                color = if (isActive) BackgroundDark else TextSecondary,
                                fontWeight = FontWeight.SemiBold,
                                fontSize = 13.sp,
                            )
                        }
                    }
                }
            }

            // Push-up count
            SectionCard(title = "Push-ups Required") {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    IconButton(
                        onClick = { if (alarm.pushUpCount > 1) viewModel.setPushUpCount(alarm.pushUpCount - 1) },
                        modifier = Modifier
                            .size(44.dp)
                            .clip(RoundedCornerShape(12.dp))
                            .background(SurfaceDark),
                    ) {
                        Icon(Icons.Default.Remove, contentDescription = "Less", tint = TextPrimary)
                    }

                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Text(
                            text = "${alarm.pushUpCount}",
                            color = GreenAccent,
                            fontWeight = FontWeight.Bold,
                            fontSize = 48.sp,
                        )
                        Text("reps", color = TextSecondary, fontSize = 14.sp)
                    }

                    IconButton(
                        onClick = { if (alarm.pushUpCount < 100) viewModel.setPushUpCount(alarm.pushUpCount + 1) },
                        modifier = Modifier
                            .size(44.dp)
                            .clip(RoundedCornerShape(12.dp))
                            .background(SurfaceDark),
                    ) {
                        Icon(Icons.Default.Add, contentDescription = "More", tint = GreenAccent)
                    }
                }

                Spacer(Modifier.height(12.dp))

                // Quick presets
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    listOf(5, 10, 15, 20, 30, 50).forEach { preset ->
                        FilterChip(
                            selected = alarm.pushUpCount == preset,
                            onClick = { viewModel.setPushUpCount(preset) },
                            label = { Text("$preset", fontSize = 12.sp) },
                            colors = FilterChipDefaults.filterChipColors(
                                selectedContainerColor = GreenAccent,
                                selectedLabelColor = BackgroundDark,
                                containerColor = SurfaceDark,
                                labelColor = TextSecondary,
                            ),
                            border = null,
                            modifier = Modifier.weight(1f),
                        )
                    }
                }
            }

            Spacer(Modifier.height(32.dp))

            // Save button
            Button(
                onClick = { viewModel.save(context) },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(56.dp),
                colors = ButtonDefaults.buttonColors(containerColor = GreenAccent, contentColor = BackgroundDark),
                shape = RoundedCornerShape(16.dp),
            ) {
                Text("Save Alarm", fontWeight = FontWeight.Bold, fontSize = 17.sp)
            }

            Spacer(Modifier.height(24.dp))
        }
    }
}

@Composable
private fun SectionCard(
    title: String,
    content: @Composable ColumnScope.() -> Unit,
) {
    Column {
        Text(
            text = title.uppercase(),
            color = TextSecondary,
            fontSize = 11.sp,
            fontWeight = FontWeight.SemiBold,
            letterSpacing = 1.sp,
            modifier = Modifier.padding(bottom = 8.dp),
        )
        Card(
            shape = RoundedCornerShape(16.dp),
            colors = CardDefaults.cardColors(containerColor = CardDark),
            modifier = Modifier.fillMaxWidth(),
        ) {
            Column(
                modifier = Modifier.padding(16.dp),
                content = content,
            )
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun TimePickerSection(
    hour: Int,
    minute: Int,
    onHourChange: (Int) -> Unit,
    onMinuteChange: (Int) -> Unit,
) {
    val state = rememberTimePickerState(
        initialHour = hour,
        initialMinute = minute,
        is24Hour = false,
    )
    LaunchedEffect(state.hour, state.minute) {
        onHourChange(state.hour)
        onMinuteChange(state.minute)
    }

    Card(
        shape = RoundedCornerShape(20.dp),
        colors = CardDefaults.cardColors(containerColor = CardDark),
        modifier = Modifier.fillMaxWidth(),
    ) {
        Box(modifier = Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
            TimePicker(
                state = state,
                colors = TimePickerDefaults.colors(
                    clockDialColor = SurfaceDark,
                    selectorColor = GreenAccent,
                    containerColor = CardDark,
                    periodSelectorBorderColor = GreenAccent,
                    clockDialSelectedContentColor = BackgroundDark,
                    clockDialUnselectedContentColor = TextPrimary,
                    timeSelectorSelectedContainerColor = GreenAccent,
                    timeSelectorUnselectedContainerColor = SurfaceDark,
                    timeSelectorSelectedContentColor = BackgroundDark,
                    timeSelectorUnselectedContentColor = TextPrimary,
                ),
            )
        }
    }
}
