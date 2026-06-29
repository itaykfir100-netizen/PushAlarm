package com.pushalarm.ui.stats

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.pushalarm.ui.theme.*

@Composable
fun StatsScreen(viewModel: StatsViewModel) {
    val stats by viewModel.stats.collectAsState()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(BackgroundDark)
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 20.dp),
    ) {
        Spacer(Modifier.height(16.dp))

        Text(
            "Stats",
            color = TextPrimary,
            fontWeight = FontWeight.Bold,
            fontSize = 34.sp,
            modifier = Modifier.padding(bottom = 20.dp),
        )

        // Highlight cards row 1
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            StatCard(
                label = "Total Push-Ups",
                value = formatBig(stats.totalPushUps),
                modifier = Modifier.weight(1f),
                highlight = true,
            )
            StatCard(
                label = "Sessions",
                value = "${stats.totalSessions}",
                modifier = Modifier.weight(1f),
            )
        }

        Spacer(Modifier.height(12.dp))

        // Streak row
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            StatCard(
                label = "Current Streak",
                value = "${stats.currentStreak}",
                unit = "days",
                modifier = Modifier.weight(1f),
                accent = if (stats.currentStreak > 0) GreenAccent else TextSecondary,
            )
            StatCard(
                label = "Best Streak",
                value = "${stats.bestStreak}",
                unit = "days",
                modifier = Modifier.weight(1f),
            )
        }

        Spacer(Modifier.height(12.dp))

        // Average
        StatCard(
            label = "Avg Push-Ups / Day",
            value = "%.1f".format(stats.avgPerDay),
            modifier = Modifier.fillMaxWidth(),
        )

        Spacer(Modifier.height(20.dp))

        // Weekly bar chart
        Text(
            "This Week",
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
            WeeklyBarChart(
                data = stats.weeklyData,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp)
                    .height(180.dp),
            )
        }

        Spacer(Modifier.height(32.dp))
    }
}

@Composable
private fun StatCard(
    label: String,
    value: String,
    modifier: Modifier = Modifier,
    unit: String = "",
    highlight: Boolean = false,
    accent: androidx.compose.ui.graphics.Color = TextPrimary,
) {
    Card(
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(
            containerColor = if (highlight) GreenAccent.copy(alpha = 0.1f) else CardDark
        ),
        modifier = modifier,
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(
                text = label.uppercase(),
                color = TextSecondary,
                fontSize = 10.sp,
                fontWeight = FontWeight.SemiBold,
                letterSpacing = 0.8.sp,
            )
            Spacer(Modifier.height(6.dp))
            Row(verticalAlignment = Alignment.Bottom) {
                Text(
                    text = value,
                    color = if (highlight) GreenAccent else accent,
                    fontWeight = FontWeight.Bold,
                    fontSize = 36.sp,
                    lineHeight = 36.sp,
                )
                if (unit.isNotEmpty()) {
                    Spacer(Modifier.width(4.dp))
                    Text(
                        text = unit,
                        color = TextSecondary,
                        fontSize = 14.sp,
                        modifier = Modifier.padding(bottom = 4.dp),
                    )
                }
            }
        }
    }
}

@Composable
private fun WeeklyBarChart(
    data: List<Pair<String, Int>>,
    modifier: Modifier = Modifier,
) {
    if (data.isEmpty()) {
        Box(modifier = modifier, contentAlignment = Alignment.Center) {
            Text("No data yet", color = TextSecondary)
        }
        return
    }
    val maxVal = data.maxOf { it.second }.coerceAtLeast(1)

    Row(
        modifier = modifier,
        horizontalArrangement = Arrangement.SpaceEvenly,
        verticalAlignment = Alignment.Bottom,
    ) {
        data.forEach { (day, reps) ->
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Bottom,
                modifier = Modifier.weight(1f),
            ) {
                // Value label
                if (reps > 0) {
                    Text(
                        text = "$reps",
                        color = GreenAccent,
                        fontSize = 10.sp,
                        fontWeight = FontWeight.Bold,
                        modifier = Modifier.padding(bottom = 4.dp),
                    )
                } else {
                    Spacer(Modifier.height(18.dp))
                }

                // Bar
                val barHeightFraction = (reps.toFloat() / maxVal).coerceIn(0.02f, 1f)
                Box(
                    modifier = Modifier
                        .fillMaxWidth(0.7f)
                        .fillMaxHeight(barHeightFraction)
                        .clip(RoundedCornerShape(topStart = 6.dp, topEnd = 6.dp))
                        .background(
                            if (reps > 0) GreenAccent.copy(alpha = 0.85f)
                            else SurfaceDark
                        ),
                )

                Spacer(Modifier.height(6.dp))

                // Day label
                Text(
                    text = day,
                    color = TextSecondary,
                    fontSize = 11.sp,
                    fontWeight = FontWeight.Medium,
                )
            }
        }
    }
}

private fun formatBig(n: Int): String = when {
    n >= 1_000_000 -> "%.1fM".format(n / 1_000_000f)
    n >= 1_000 -> "%.1fK".format(n / 1_000f)
    else -> "$n"
}
