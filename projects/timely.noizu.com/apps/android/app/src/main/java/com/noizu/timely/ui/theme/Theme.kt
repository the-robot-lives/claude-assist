package com.noizu.timely.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Typography
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/**
 * MACOS-STYLEGUIDE.md translated to Material 3.
 *
 * The brief is "Minimal Tech 80%, Editorial 20%, calm, precise, serious" with
 * dense operational surfaces. Two things follow that are worth stating, because
 * both are easy to undo by accident:
 *
 *   - **No dynamic color.** Material You would repaint Timely with the user's
 *     wallpaper palette, and the semantic colors below carry meaning -- billable
 *     is green, disputed is red. Letting the OS choose them would make the
 *     status pills lie.
 *   - **Density over air.** Spacing is on an 8dp base with 12dp compact groups,
 *     not the generous default Material rhythm; a day's timeline has to be
 *     scannable without scrolling past three rows.
 */

private val Accent = Color(0xFFD61F73)
private val Success = Color(0xFF1AA352)
private val Warning = Color(0xFFC77A1A)
private val Danger = Color(0xFFC72424)

private val InkLight = Color(0xFF12161B)
private val SurfaceLight = Color(0xFFFFFFFF)
private val BackgroundLight = Color(0xFFF7F7F5)
private val OutlineLight = Color(0xFFDDDDD8)
private val MutedLight = Color(0xFF5F6B66)

private val InkDark = Color(0xFFF2F2EF)
private val SurfaceDark = Color(0xFF1A1F25)
private val BackgroundDark = Color(0xFF12161B)
private val OutlineDark = Color(0xFF333B44)
private val MutedDark = Color(0xFFA3ADB5)

private val LightColors = lightColorScheme(
    primary = Accent,
    onPrimary = Color.White,
    secondary = MutedLight,
    onSecondary = Color.White,
    background = BackgroundLight,
    onBackground = InkLight,
    surface = SurfaceLight,
    onSurface = InkLight,
    surfaceVariant = BackgroundLight,
    onSurfaceVariant = MutedLight,
    outline = OutlineLight,
    error = Danger,
    onError = Color.White,
)

private val DarkColors = darkColorScheme(
    primary = Accent,
    onPrimary = Color.White,
    secondary = MutedDark,
    onSecondary = InkDark,
    background = BackgroundDark,
    onBackground = InkDark,
    surface = SurfaceDark,
    onSurface = InkDark,
    surfaceVariant = Color(0xFF232A31),
    onSurfaceVariant = MutedDark,
    outline = OutlineDark,
    error = Color(0xFFE86A6A),
    onError = Color(0xFF2A0A0A),
)

/**
 * The semantic colors, kept out of [MaterialTheme.colorScheme] on purpose.
 *
 * Material's scheme has no slot that means "billable" or "disputed". Squeezing
 * them into `tertiary` and `errorContainer` would make every call site a riddle
 * and would break the moment someone rebalances the scheme.
 */
data class TimelySemantics(
    val success: Color,
    val warning: Color,
    val danger: Color,
    val muted: Color,
    /** Verified: server evidence backs this span. */
    val verified: Color,
    /** Inferred: a model proposed it and nobody has confirmed it. */
    val inferred: Color,
    /** Manual: a human typed it. */
    val manual: Color,
    /** Private: redacted, evidence withheld. */
    val private: Color,
    /** Disputed: flagged, needs a decision. */
    val disputed: Color,
    /** Approved: signed off, billable-ready. */
    val approved: Color,
)

val LocalTimelySemantics = staticCompositionLocalOf {
    TimelySemantics(
        success = Success,
        warning = Warning,
        danger = Danger,
        muted = MutedLight,
        verified = Success,
        inferred = Warning,
        manual = Color(0xFF3E6EA8),
        private = Color(0xFF6B5CA5),
        disputed = Danger,
        approved = Color(0xFF14806A),
    )
}

/** 8dp base, 12dp compact groups, 16dp cards, 24dp page padding. */
object Spacing {
    val hairline = 1.dp
    val tight = 4.dp
    val base = 8.dp
    val compact = 12.dp
    val card = 16.dp
    val page = 24.dp
}

object Radii {
    val card = 8.dp
    val button = 6.dp
    val pill = 999.dp
}

private val TimelyTypography = Typography(
    headlineLarge = TextStyle(fontSize = 30.sp, fontWeight = FontWeight.SemiBold, lineHeight = 36.sp),
    headlineMedium = TextStyle(fontSize = 22.sp, fontWeight = FontWeight.SemiBold, lineHeight = 28.sp),
    titleMedium = TextStyle(fontSize = 16.sp, fontWeight = FontWeight.SemiBold, lineHeight = 22.sp),
    bodyLarge = TextStyle(fontSize = 15.sp, lineHeight = 21.sp),
    bodyMedium = TextStyle(fontSize = 14.sp, lineHeight = 20.sp),
    labelLarge = TextStyle(fontSize = 13.sp, fontWeight = FontWeight.Medium, lineHeight = 18.sp),
    labelMedium = TextStyle(fontSize = 12.sp, fontWeight = FontWeight.Medium, lineHeight = 16.sp),
    labelSmall = TextStyle(fontSize = 11.sp, fontWeight = FontWeight.Medium, lineHeight = 15.sp),
)

@Composable
fun TimelyTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit,
) {
    val semantics = LocalTimelySemantics.current.copy(
        muted = if (darkTheme) MutedDark else MutedLight,
    )
    CompositionLocalProvider(LocalTimelySemantics provides semantics) {
        MaterialTheme(
            colorScheme = if (darkTheme) DarkColors else LightColors,
            typography = TimelyTypography,
            content = content,
        )
    }
}
