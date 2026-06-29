package com.pushalarm.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable

private val DarkColorScheme = darkColorScheme(
    primary = GreenAccent,
    onPrimary = BackgroundDark,
    secondary = GreenDim,
    onSecondary = BackgroundDark,
    background = BackgroundDark,
    surface = SurfaceDark,
    onBackground = TextPrimary,
    onSurface = TextPrimary,
    error = RedAccent,
)

@Composable
fun PushAlarmTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = DarkColorScheme,
        typography = Typography,
        content = content,
    )
}
