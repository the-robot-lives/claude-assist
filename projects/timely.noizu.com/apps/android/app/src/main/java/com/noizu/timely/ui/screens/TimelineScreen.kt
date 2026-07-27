package com.noizu.timely.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.Checkbox
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import com.noizu.timely.data.local.TimeSpanEntity
import com.noizu.timely.ui.DayUiState
import com.noizu.timely.ui.components.EmptyState
import com.noizu.timely.ui.components.SectionHeader
import com.noizu.timely.ui.theme.Spacing
import java.time.Instant
import java.time.format.DateTimeFormatter

/**
 * The correction surface: split, merge, reassign, retitle, toggle billable.
 *
 * Multi-select is the interaction that makes merge possible on a phone, so
 * selection state lives here rather than in the view model -- it is transient
 * screen state, and persisting it would resurrect a stale selection after a
 * sync changed the rows underneath it.
 */
@Composable
fun TimelineScreen(
    state: DayUiState,
    onPreviousDay: () -> Unit,
    onNextDay: () -> Unit,
    onRetitle: (String, String) -> Unit,
    onToggleBillable: (TimeSpanEntity) -> Unit,
    onReassign: (String, String, String, String) -> Unit,
    onSplit: (String, Instant) -> Unit,
    onMerge: (List<String>) -> Unit,
    modifier: Modifier = Modifier,
) {
    var selected by remember(state.day) { mutableStateOf(setOf<String>()) }
    var editing by remember { mutableStateOf<TimeSpanEntity?>(null) }
    var splitting by remember { mutableStateOf<TimeSpanEntity?>(null) }

    Box(modifier.fillMaxSize()) {
        LazyColumn(
            modifier = Modifier.fillMaxSize().padding(horizontal = Spacing.card),
            verticalArrangement = Arrangement.spacedBy(Spacing.base),
            contentPadding = androidx.compose.foundation.layout.PaddingValues(vertical = Spacing.card),
        ) {
            item {
                Row(
                    Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    TextButton(onClick = onPreviousDay) { Text("< Previous") }
                    Text(
                        state.day.format(DateTimeFormatter.ofPattern("d MMM yyyy")),
                        style = MaterialTheme.typography.titleMedium,
                    )
                    TextButton(onClick = onNextDay) { Text("Next >") }
                }
            }

            if (state.spans.isEmpty()) {
                item { EmptyState("Nothing recorded for this day.") }
            } else {
                item {
                    SectionHeader(
                        "${state.spans.size} spans",
                        "Select two or more to merge. Tap a span to edit it.",
                    )
                }
                items(state.spans, key = { it.id }) { span ->
                    Row(
                        Modifier.fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(Spacing.base),
                    ) {
                        Checkbox(
                            checked = span.id in selected,
                            onCheckedChange = { checked ->
                                selected = if (checked) selected + span.id else selected - span.id
                            },
                        )
                        Column(Modifier.weight(1f)) {
                            SpanRow(
                                span = span,
                                flagged = span.id in state.flaggedSpanIds,
                                onClick = { editing = span },
                            )
                            Row(
                                horizontalArrangement = Arrangement.spacedBy(Spacing.base),
                                modifier = Modifier.padding(top = Spacing.tight),
                            ) {
                                TextButton(onClick = { onToggleBillable(span) }) {
                                    Text(if (span.isBillable) "Mark non-billable" else "Mark billable")
                                }
                                if (span.endEpochSeconds != null) {
                                    TextButton(onClick = { splitting = span }) { Text("Split") }
                                }
                            }
                        }
                    }
                }
            }
        }

        if (selected.size >= 2) {
            Button(
                onClick = { onMerge(selected.toList()); selected = emptySet() },
                modifier = Modifier
                    .align(Alignment.BottomCenter)
                    .padding(Spacing.card)
                    .fillMaxWidth(),
            ) {
                Text("Merge ${selected.size} spans")
            }
        }
    }

    editing?.let { span ->
        EditSpanDialog(
            span = span,
            onDismiss = { editing = null },
            onSave = { title, client, project, ticket ->
                if (title != span.title) onRetitle(span.id, title)
                if (client != span.clientName || project != span.projectName ||
                    ticket != span.ticketName
                ) {
                    onReassign(span.id, client, project, ticket)
                }
                editing = null
            },
        )
    }

    splitting?.let { span ->
        SplitSpanDialog(
            span = span,
            onDismiss = { splitting = null },
            onSplit = { at -> onSplit(span.id, at); splitting = null },
        )
    }
}

@Composable
private fun EditSpanDialog(
    span: TimeSpanEntity,
    onDismiss: () -> Unit,
    onSave: (String, String, String, String) -> Unit,
) {
    var title by remember { mutableStateOf(span.title) }
    var client by remember { mutableStateOf(span.clientName) }
    var project by remember { mutableStateOf(span.projectName) }
    var ticket by remember { mutableStateOf(span.ticketName) }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Edit span") },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(Spacing.base)) {
                OutlinedTextField(
                    value = title,
                    onValueChange = { title = it },
                    label = { Text("Title") },
                    singleLine = true,
                )
                OutlinedTextField(
                    value = client,
                    onValueChange = { client = it },
                    label = { Text("Client") },
                    singleLine = true,
                )
                OutlinedTextField(
                    value = project,
                    onValueChange = { project = it },
                    label = { Text("Project") },
                    singleLine = true,
                )
                OutlinedTextField(
                    value = ticket,
                    onValueChange = { ticket = it },
                    label = { Text("Ticket") },
                    singleLine = true,
                )
                Text(
                    "Names are matched case- and spacing-insensitively, so this " +
                        "will attach to the existing project rather than creating a " +
                        "second one.",
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
        },
        confirmButton = {
            Button(onClick = { onSave(title, client, project, ticket) }) { Text("Save") }
        },
        dismissButton = { OutlinedButton(onClick = onDismiss) { Text("Cancel") } },
    )
}

@Composable
private fun SplitSpanDialog(
    span: TimeSpanEntity,
    onDismiss: () -> Unit,
    onSplit: (Instant) -> Unit,
) {
    val start = span.startEpochSeconds
    val end = span.endEpochSeconds ?: start
    val midpoint = start + (end - start) / 2
    var minutesFromStart by remember {
        mutableStateOf((((midpoint - start) / 60).toInt()).toString())
    }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Split span") },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(Spacing.base)) {
                Text(
                    "${timeRangeLabel(span)} - split into two spans.",
                    style = MaterialTheme.typography.bodyMedium,
                )
                OutlinedTextField(
                    value = minutesFromStart,
                    onValueChange = { minutesFromStart = it.filter(Char::isDigit) },
                    label = { Text("Minutes after start") },
                    singleLine = true,
                )
                Text(
                    "Both halves keep the original as their source, so the split " +
                        "stays auditable.",
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
        },
        confirmButton = {
            val minutes = minutesFromStart.toLongOrNull() ?: 0L
            val at = Instant.ofEpochSecond(start + minutes * 60)
            Button(
                // A cut outside the span produces no pieces at all, so it is
                // refused here rather than silently doing nothing.
                enabled = minutes > 0 && start + minutes * 60 < end,
                onClick = { onSplit(at) },
            ) { Text("Split") }
        },
        dismissButton = { OutlinedButton(onClick = onDismiss) { Text("Cancel") } },
    )
}
