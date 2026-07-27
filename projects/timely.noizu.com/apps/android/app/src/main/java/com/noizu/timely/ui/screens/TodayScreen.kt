package com.noizu.timely.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.noizu.timely.data.local.ReviewItemEntity
import com.noizu.timely.data.local.TimeSpanEntity
import com.noizu.timely.ui.DayUiState
import com.noizu.timely.ui.asHoursLabel
import com.noizu.timely.ui.components.EmptyState
import com.noizu.timely.ui.components.MetricTile
import com.noizu.timely.ui.components.SectionHeader
import com.noizu.timely.ui.components.SyncStatusBar
import com.noizu.timely.ui.theme.Spacing
import java.time.Instant
import java.time.format.DateTimeFormatter

/**
 * Today: the Daily Review entry point.
 *
 * Ordered by what needs a decision, not by what is prettiest: unresolved idle
 * gaps and flags come before the metrics summary, because "review beats recall"
 * only works if the thing needing review is the thing the user sees first.
 */
@Composable
fun TodayScreen(
    state: DayUiState,
    onRefresh: () -> Unit,
    onOpenSpan: (String) -> Unit,
    onCloseOpenSpan: (String, Instant) -> Unit,
    onResolveReview: (String, String) -> Unit,
    onApproveDay: () -> Unit,
    onAddManual: () -> Unit,
    modifier: Modifier = Modifier,
) {
    LazyColumn(
        modifier = modifier.fillMaxSize().padding(horizontal = Spacing.card),
        verticalArrangement = Arrangement.spacedBy(Spacing.compact),
        contentPadding = androidx.compose.foundation.layout.PaddingValues(vertical = Spacing.card),
    ) {
        item {
            SyncStatusBar(
                pendingCount = state.pendingCount,
                reauthRequired = state.session.reauthRequired || !state.session.isSignedIn,
                isSyncing = state.isSyncing,
                lastError = state.syncState?.lastError,
            )
        }

        item {
            Row(
                Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(Spacing.base),
            ) {
                MetricTile(
                    label = "Tracked",
                    value = state.totalSeconds.asHoursLabel(),
                    detail = "${state.spans.size} span${if (state.spans.size == 1) "" else "s"}",
                    modifier = Modifier.weight(1f),
                )
                MetricTile(
                    label = "Billable",
                    value = state.billableSeconds.asHoursLabel(),
                    detail = percentLabel(state.billableSeconds, state.totalSeconds),
                    modifier = Modifier.weight(1f),
                )
            }
        }
        item {
            Row(
                Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(Spacing.base),
            ) {
                MetricTile(
                    label = "Needs review",
                    value = state.needsReview.size.toString(),
                    detail = if (state.needsReview.isEmpty()) "Nothing waiting" else "Resolve below",
                    modifier = Modifier.weight(1f),
                )
                MetricTile(
                    label = "Open spans",
                    value = state.openSpans.size.toString(),
                    detail = if (state.openSpans.isEmpty()) "All closed" else "Still running",
                    modifier = Modifier.weight(1f),
                )
            }
        }

        // Open spans first: an unresolved idle gap is the most actionable thing
        // on the screen.
        if (state.openSpans.isNotEmpty()) {
            item { SectionHeader("Still open", "Close these to make the day's totals honest.") }
            items(state.openSpans, key = { it.id }) { span ->
                OpenSpanRow(
                    span = span,
                    onClose = { onCloseOpenSpan(span.id, Instant.now()) },
                    onOpen = { onOpenSpan(span.id) },
                )
            }
        }

        val openFlags = state.reviewItems.filter { it.resolvedAt == null }
        if (openFlags.isNotEmpty()) {
            item {
                SectionHeader(
                    "Flagged for review",
                    "Raised by the server. Nothing is merged or removed automatically.",
                )
            }
            items(openFlags, key = { it.id }) { item ->
                ReviewFlagRow(
                    item = item,
                    onOpen = { onOpenSpan(item.targetId) },
                    onResolve = { resolution -> onResolveReview(item.id, resolution) },
                )
            }
        }

        item { SectionHeader("Day timeline", state.day.format(DAY_FORMAT)) }
        if (state.spans.isEmpty()) {
            item {
                EmptyState(
                    "No time recorded for this day. Add an entry, or pull to sync " +
                        "what the desktop agent captured.",
                )
            }
        } else {
            items(state.spans, key = { it.id }) { span ->
                SpanRow(
                    span = span,
                    flagged = span.id in state.flaggedSpanIds,
                    onClick = { onOpenSpan(span.id) },
                )
            }
        }

        item {
            Row(
                Modifier.fillMaxWidth().padding(top = Spacing.base),
                horizontalArrangement = Arrangement.spacedBy(Spacing.base),
            ) {
                Button(onClick = onAddManual, modifier = Modifier.weight(1f)) {
                    Text("Add entry")
                }
                OutlinedButton(onClick = onRefresh, modifier = Modifier.weight(1f)) {
                    Text(if (state.isSyncing) "Syncing…" else "Sync now")
                }
            }
        }

        if (state.spans.isNotEmpty()) {
            item {
                TextButton(onClick = onApproveDay, modifier = Modifier.fillMaxWidth()) {
                    Text("Approve this day")
                }
            }
        }
    }
}

@Composable
private fun OpenSpanRow(span: TimeSpanEntity, onClose: () -> Unit, onOpen: () -> Unit) {
    SpanCard(onClick = onOpen) {
        Column(verticalArrangement = Arrangement.spacedBy(Spacing.base)) {
            SpanHeadline(span = span, flagged = false)
            Text(
                "Started ${formatTime(span.startEpochSeconds)}, still running.",
                style = MaterialTheme.typography.labelMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            Button(onClick = onClose) { Text("Close now") }
        }
    }
}

@Composable
private fun ReviewFlagRow(
    item: ReviewItemEntity,
    onOpen: () -> Unit,
    onResolve: (String) -> Unit,
) {
    SpanCard(onClick = onOpen) {
        Column(verticalArrangement = Arrangement.spacedBy(Spacing.base)) {
            Text(item.code.humanizeReviewCode(), style = MaterialTheme.typography.titleMedium)
            item.detail?.let {
                Text(
                    it,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
            Text(
                explainReviewCode(item.code),
                style = MaterialTheme.typography.labelMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            // Three explicit choices. There is deliberately no "resolve
            // automatically": the server refuses to guess which of two
            // overlapping billable spans is real, and so does this.
            Row(horizontalArrangement = Arrangement.spacedBy(Spacing.base)) {
                OutlinedButton(onClick = { onResolve("dismissed") }) { Text("Dismiss") }
                OutlinedButton(onClick = { onResolve("accepted") }) { Text("Accept") }
                OutlinedButton(onClick = { onResolve("merged") }) { Text("Merged") }
            }
        }
    }
}

internal fun String.humanizeReviewCode(): String = when (this) {
    "suspected_duplicate" -> "Possible duplicate"
    "billing_overlap" -> "Billing overlap"
    "unresolved_idle_gap" -> "Unresolved idle gap"
    "low_confidence" -> "Low confidence"
    "unresolved_reference" -> "Unresolved project reference"
    "auto_created_entity" -> "Auto-created project or client"
    "privacy_censored" -> "Evidence redacted"
    "reopened_after_approval" -> "Reopened after approval"
    "duplicate_name" -> "That name is already taken"
    "span_reopen_forbidden" -> "Could not reopen a closed span"
    "locked_day" -> "That day is locked"
    else -> replace('_', ' ').replaceFirstChar { it.uppercase() }
}

private fun explainReviewCode(code: String): String = when (code) {
    "suspected_duplicate" ->
        "Two spans look like the same work. Nothing has been merged - you decide."
    "billing_overlap" ->
        "Two billable spans overlap under different clients. Someone may be billed twice."
    "span_reopen_forbidden" ->
        "This device had not seen the span close, so the change was refused. Pull and retry."
    "locked_day" -> "The day was approved and locked before this edit reached the server."
    else -> "Raised for review. Your data has not been changed."
}

private val DAY_FORMAT: DateTimeFormatter = DateTimeFormatter.ofPattern("EEEE, d MMMM")

internal fun percentLabel(part: Long, whole: Long): String =
    if (whole <= 0) "-" else "${(part * 100 / whole)}% of tracked"
