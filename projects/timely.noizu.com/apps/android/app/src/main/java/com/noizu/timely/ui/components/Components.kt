package com.noizu.timely.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.ErrorOutline
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Psychology
import androidx.compose.material.icons.filled.VerifiedUser
import androidx.compose.material.icons.filled.Verified
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import com.noizu.timely.data.local.TimeSpanEntity
import com.noizu.timely.ui.theme.LocalTimelySemantics
import com.noizu.timely.ui.theme.Radii
import com.noizu.timely.ui.theme.Spacing

/**
 * "Confidence is visible" (UX brief principle 4).
 *
 * The six states are a product concept, not a rendering detail, so they are an
 * enum rather than an ad-hoc string comparison at each call site -- a screen
 * that forgets one would silently show a disputed span as ordinary.
 */
enum class ConfidenceState(val label: String) {
    VERIFIED("Verified"),
    INFERRED("Inferred"),
    MANUAL("Manual"),
    PRIVATE("Private"),
    DISPUTED("Disputed"),
    APPROVED("Approved"),
}

/**
 * Order matters here. A disputed span that also happens to be manual is
 * *disputed* -- the state that needs a human decision has to win, or the flag
 * that matters gets hidden behind a benign one.
 */
fun TimeSpanEntity.confidenceState(hasOpenReviewFlag: Boolean = false): ConfidenceState = when {
    reviewState == "disputed" || hasOpenReviewFlag -> ConfidenceState.DISPUTED
    reviewState == "approved" || reviewState == "locked" -> ConfidenceState.APPROVED
    reviewState == "needs_review" -> ConfidenceState.DISPUTED
    source == "manual" -> ConfidenceState.MANUAL
    reviewState == "reviewed" -> ConfidenceState.VERIFIED
    else -> ConfidenceState.INFERRED
}

@Composable
fun ConfidenceState.color(): Color {
    val s = LocalTimelySemantics.current
    return when (this) {
        ConfidenceState.VERIFIED -> s.verified
        ConfidenceState.INFERRED -> s.inferred
        ConfidenceState.MANUAL -> s.manual
        ConfidenceState.PRIVATE -> s.private
        ConfidenceState.DISPUTED -> s.disputed
        ConfidenceState.APPROVED -> s.approved
    }
}

fun ConfidenceState.icon(): ImageVector = when (this) {
    ConfidenceState.VERIFIED -> Icons.Filled.Verified
    ConfidenceState.INFERRED -> Icons.Filled.Psychology
    ConfidenceState.MANUAL -> Icons.Filled.Edit
    ConfidenceState.PRIVATE -> Icons.Filled.VerifiedUser
    ConfidenceState.DISPUTED -> Icons.Filled.ErrorOutline
    ConfidenceState.APPROVED -> Icons.Filled.CheckCircle
}

/**
 * Icon + label + semantic color, never color alone (styleguide accessibility
 * rule). A colour-blind user and a screen-reader user both get the state, and
 * so does anyone looking at a greyscale screenshot in a bug report.
 */
@Composable
fun StatusPill(
    state: ConfidenceState,
    modifier: Modifier = Modifier,
) {
    val tint = state.color()
    Row(
        modifier = modifier
            .background(tint.copy(alpha = 0.10f), RoundedCornerShape(Radii.pill))
            .border(1.dp, tint.copy(alpha = 0.35f), RoundedCornerShape(Radii.pill))
            .padding(horizontal = Spacing.base, vertical = Spacing.tight)
            .semantics { contentDescription = "Confidence: ${state.label}" },
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(Spacing.tight),
    ) {
        Icon(
            imageVector = state.icon(),
            contentDescription = null,
            tint = tint,
            modifier = Modifier.size(14.dp),
        )
        Text(state.label, style = MaterialTheme.typography.labelSmall, color = tint)
    }
}

@Composable
fun BillablePill(isBillable: Boolean, modifier: Modifier = Modifier) {
    val s = LocalTimelySemantics.current
    val tint = if (isBillable) s.success else s.muted
    val label = if (isBillable) "Billable" else "Non-billable"
    Row(
        modifier = modifier
            .background(tint.copy(alpha = 0.10f), RoundedCornerShape(Radii.pill))
            .padding(horizontal = Spacing.base, vertical = Spacing.tight)
            .semantics { contentDescription = label },
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(label, style = MaterialTheme.typography.labelSmall, color = tint)
    }
}

/** Icon, label, large value, short detail (styleguide "metric tile"). */
@Composable
fun MetricTile(
    label: String,
    value: String,
    detail: String? = null,
    modifier: Modifier = Modifier,
) {
    Card(
        modifier = modifier,
        shape = RoundedCornerShape(Radii.card),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        border = androidx.compose.foundation.BorderStroke(
            1.dp,
            MaterialTheme.colorScheme.outline,
        ),
    ) {
        Column(Modifier.padding(Spacing.card), verticalArrangement = Arrangement.spacedBy(Spacing.tight)) {
            Text(
                label,
                style = MaterialTheme.typography.labelMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            Text(value, style = MaterialTheme.typography.headlineMedium)
            detail?.let {
                Text(
                    it,
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
        }
    }
}

@Composable
fun SectionHeader(title: String, detail: String? = null, modifier: Modifier = Modifier) {
    Column(modifier.padding(top = Spacing.base), verticalArrangement = Arrangement.spacedBy(2.dp)) {
        Text(title, style = MaterialTheme.typography.titleMedium)
        detail?.let {
            Text(
                it,
                style = MaterialTheme.typography.labelMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
    }
}

/** Compact neutral row with a concrete next step (styleguide "empty state"). */
@Composable
fun EmptyState(message: String, modifier: Modifier = Modifier) {
    Card(
        modifier = modifier.fillMaxWidth(),
        shape = RoundedCornerShape(Radii.card),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant,
        ),
    ) {
        Text(
            message,
            modifier = Modifier.padding(Spacing.card),
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
    }
}

/**
 * The honest sync status line.
 *
 * Says what is true rather than what is reassuring: how many edits are waiting,
 * and whether the reason they are waiting is the network or an expired session.
 * A user who cannot tell "saved locally" from "saved to the server" will
 * eventually lose work and blame the app -- correctly.
 */
@Composable
fun SyncStatusBar(
    pendingCount: Int,
    reauthRequired: Boolean,
    isSyncing: Boolean,
    lastError: String?,
    modifier: Modifier = Modifier,
) {
    val s = LocalTimelySemantics.current
    val (tint, message) = when {
        reauthRequired && pendingCount > 0 ->
            s.warning to "$pendingCount change${plural(pendingCount)} saved on this device. Sign in to sync."
        reauthRequired -> s.warning to "Signed out. Your timeline is still editable here."
        isSyncing -> s.muted to "Syncing…"
        pendingCount > 0 -> s.muted to "$pendingCount change${plural(pendingCount)} waiting to sync."
        lastError != null -> s.warning to "Last sync failed. Your changes are safe on this device."
        else -> s.success to "All changes synced."
    }
    Row(
        modifier = modifier
            .fillMaxWidth()
            .background(tint.copy(alpha = 0.08f), RoundedCornerShape(Radii.button))
            .padding(horizontal = Spacing.compact, vertical = Spacing.base),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(Spacing.base),
    ) {
        Icon(
            imageVector = if (reauthRequired) Icons.Filled.Lock else Icons.Filled.CheckCircle,
            contentDescription = null,
            tint = tint,
            modifier = Modifier.size(14.dp),
        )
        Text(message, style = MaterialTheme.typography.labelMedium, color = tint)
    }
}

private fun plural(n: Int) = if (n == 1) "" else "s"
