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
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.noizu.timely.data.local.TimeSpanEntity
import com.noizu.timely.ui.DayUiState
import com.noizu.timely.ui.asHoursLabel
import com.noizu.timely.ui.elapsedSeconds
import com.noizu.timely.ui.components.EmptyState
import com.noizu.timely.ui.components.SectionHeader
import com.noizu.timely.ui.theme.Spacing
import java.time.Instant

/**
 * Idle-prompt resolution.
 *
 * An open span and a low-confidence span are the same question in two shapes:
 * "was this really work, and whose?" Both are answered with the same three
 * choices, and none of them is pre-selected -- the point of the prompt is that
 * the device does not know, and guessing on the user's behalf is what erodes
 * trust in the timeline.
 */
@Composable
fun IdleReviewScreen(
    state: DayUiState,
    onKeep: (TimeSpanEntity) -> Unit,
    onDiscard: (TimeSpanEntity) -> Unit,
    onCloseNow: (TimeSpanEntity) -> Unit,
    onOpenSpan: (String) -> Unit,
    modifier: Modifier = Modifier,
) {
    val open = state.openSpans
    val lowConfidence = state.spans.filter {
        it.reviewState == "unreviewed" || it.reviewState == "needs_review"
    }

    LazyColumn(
        modifier = modifier.fillMaxSize().padding(horizontal = Spacing.card),
        verticalArrangement = Arrangement.spacedBy(Spacing.compact),
        contentPadding = androidx.compose.foundation.layout.PaddingValues(vertical = Spacing.card),
    ) {
        if (open.isEmpty() && lowConfidence.isEmpty()) {
            item {
                EmptyState("Nothing to resolve. Every span on this day has an end and a decision.")
            }
        }

        if (open.isNotEmpty()) {
            item {
                SectionHeader(
                    "Open spans",
                    "These have no end time, so they keep counting. Close them to make " +
                        "the day's totals real.",
                )
            }
            items(open, key = { it.id }) { span ->
                SpanCard(onClick = { onOpenSpan(span.id) }) {
                    Column(verticalArrangement = Arrangement.spacedBy(Spacing.base)) {
                        SpanHeadline(span, flagged = false)
                        Text(
                            "Running for ${span.elapsedSeconds().asHoursLabel()}.",
                            style = MaterialTheme.typography.labelMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                        )
                        Row(
                            Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(Spacing.base),
                        ) {
                            Button(
                                onClick = { onCloseNow(span) },
                                modifier = Modifier.weight(1f),
                            ) { Text("Close now") }
                            OutlinedButton(
                                onClick = { onDiscard(span) },
                                modifier = Modifier.weight(1f),
                            ) { Text("Not work") }
                        }
                    }
                }
            }
        }

        if (lowConfidence.isNotEmpty()) {
            item {
                SectionHeader(
                    "Needs a decision",
                    "Inferred or unconfirmed time. Confirming marks it verified; it is " +
                        "not counted as reviewed until you say so.",
                )
            }
            items(lowConfidence, key = { it.id }) { span ->
                SpanCard(onClick = { onOpenSpan(span.id) }) {
                    Column(verticalArrangement = Arrangement.spacedBy(Spacing.base)) {
                        SpanHeadline(span, flagged = span.id in state.flaggedSpanIds)
                        Row(
                            Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(Spacing.base),
                        ) {
                            Button(
                                onClick = { onKeep(span) },
                                modifier = Modifier.weight(1f),
                            ) { Text("Confirm") }
                            OutlinedButton(
                                onClick = { onDiscard(span) },
                                modifier = Modifier.weight(1f),
                            ) { Text("Not work") }
                        }
                    }
                }
            }
        }
    }
}

/** Convenience for the "close now" action, kept here so the screen stays declarative. */
fun nowInstant(): Instant = Instant.now()
