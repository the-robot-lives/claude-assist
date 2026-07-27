package com.noizu.timely.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.noizu.timely.data.local.TimeSpanEntity
import com.noizu.timely.ui.asHoursLabel
import com.noizu.timely.ui.elapsedSeconds
import com.noizu.timely.ui.components.BillablePill
import com.noizu.timely.ui.components.StatusPill
import com.noizu.timely.ui.components.confidenceState
import com.noizu.timely.ui.theme.Radii
import com.noizu.timely.ui.theme.Spacing
import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter

@Composable
fun SpanCard(
    onClick: (() -> Unit)? = null,
    modifier: Modifier = Modifier,
    content: @Composable () -> Unit,
) {
    Card(
        modifier = modifier.fillMaxWidth(),
        shape = RoundedCornerShape(Radii.card),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        border = androidx.compose.foundation.BorderStroke(1.dp, MaterialTheme.colorScheme.outline),
        onClick = onClick ?: {},
        enabled = onClick != null,
    ) {
        Column(Modifier.padding(Spacing.card)) { content() }
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
fun SpanHeadline(span: TimeSpanEntity, flagged: Boolean) {
    Column(verticalArrangement = Arrangement.spacedBy(Spacing.tight)) {
        Row(
            Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.Top,
        ) {
            Text(
                text = span.title.ifBlank { "Untitled" },
                style = MaterialTheme.typography.titleMedium,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
                modifier = Modifier.weight(1f),
            )
            Text(
                text = span.elapsedSeconds().asHoursLabel(),
                style = MaterialTheme.typography.titleMedium,
            )
        }

        val path = listOf(span.clientName, span.projectName, span.ticketName)
            .filter { it.isNotBlank() }
            .joinToString(" / ")
        if (path.isNotBlank()) {
            Text(
                path,
                style = MaterialTheme.typography.labelMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
        }

        Text(
            timeRangeLabel(span),
            style = MaterialTheme.typography.labelMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )

        FlowRow(horizontalArrangement = Arrangement.spacedBy(Spacing.tight)) {
            StatusPill(span.confidenceState(hasOpenReviewFlag = flagged))
            BillablePill(span.isBillable)
            if (span.pendingLocal) {
                // The user needs to be able to tell "saved here" from "saved on
                // the server" without guessing.
                Text(
                    "Not yet synced",
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.padding(
                        horizontal = Spacing.base,
                        vertical = Spacing.tight,
                    ),
                )
            }
        }
    }
}

@Composable
fun SpanRow(span: TimeSpanEntity, flagged: Boolean, onClick: () -> Unit) {
    SpanCard(onClick = onClick) { SpanHeadline(span = span, flagged = flagged) }
}

private val TIME_FORMAT: DateTimeFormatter =
    DateTimeFormatter.ofPattern("HH:mm").withZone(ZoneId.systemDefault())

fun formatTime(epochSeconds: Long): String =
    TIME_FORMAT.format(Instant.ofEpochSecond(epochSeconds))

fun timeRangeLabel(span: TimeSpanEntity): String {
    val start = formatTime(span.startEpochSeconds)
    val end = span.endEpochSeconds?.let { formatTime(it) } ?: "now"
    return "$start - $end"
}
