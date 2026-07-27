package com.noizu.timely.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.FilterChip
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import com.noizu.timely.ui.ReportsUiState
import com.noizu.timely.ui.asHoursLabel
import com.noizu.timely.ui.components.EmptyState
import com.noizu.timely.ui.components.MetricTile
import com.noizu.timely.ui.components.SectionHeader
import com.noizu.timely.ui.theme.Spacing
import java.time.format.DateTimeFormatter

/**
 * Summary by project.
 *
 * Computed from the local mirror rather than `/api/v1/reports/summary`, so the
 * screen still works on a plane. The trade-off is stated on the screen: these
 * are the numbers this device knows about, which is not the same as the numbers
 * the server will invoice. Hiding that distinction would be the dishonest
 * choice, since unsynced spans are exactly the ones a user is least sure about.
 */
@Composable
fun ReportsScreen(
    state: ReportsUiState,
    onLastSevenDays: () -> Unit,
    onThisMonth: () -> Unit,
    modifier: Modifier = Modifier,
) {
    var selection by remember { mutableStateOf(RangeChoice.WEEK) }

    LazyColumn(
        modifier = modifier.fillMaxSize().padding(horizontal = Spacing.card),
        verticalArrangement = Arrangement.spacedBy(Spacing.compact),
        contentPadding = androidx.compose.foundation.layout.PaddingValues(vertical = Spacing.card),
    ) {
        item {
            Row(horizontalArrangement = Arrangement.spacedBy(Spacing.base)) {
                FilterChip(
                    selected = selection == RangeChoice.WEEK,
                    onClick = { selection = RangeChoice.WEEK; onLastSevenDays() },
                    label = { Text("Last 7 days") },
                )
                FilterChip(
                    selected = selection == RangeChoice.MONTH,
                    onClick = { selection = RangeChoice.MONTH; onThisMonth() },
                    label = { Text("This month") },
                )
            }
        }

        item {
            Text(
                "${state.from.format(RANGE_FORMAT)} - ${state.to.format(RANGE_FORMAT)}",
                style = MaterialTheme.typography.labelMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
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

        if (state.unreviewedCount > 0) {
            item {
                MetricTile(
                    label = "Unreviewed",
                    value = state.unreviewedCount.toString(),
                    detail = "Not yet confirmed - review before invoicing",
                    modifier = Modifier.fillMaxWidth(),
                )
            }
        }

        item { SectionHeader("By project") }

        if (state.groups.isEmpty()) {
            item { EmptyState("No time in this range.") }
        } else {
            items(state.groups, key = { it.label }) { group ->
                Row(
                    Modifier.fillMaxWidth().padding(vertical = Spacing.base),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Column(Modifier.weight(1f)) {
                        Text(group.label, style = MaterialTheme.typography.bodyLarge)
                        Text(
                            "${group.billableSeconds.asHoursLabel()} billable",
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                        )
                    }
                    Text(group.seconds.asHoursLabel(), style = MaterialTheme.typography.titleMedium)
                }
            }
        }

        item {
            Text(
                "Totals are calculated from time stored on this device. Spans that " +
                    "have not synced yet are included here but not in server-side " +
                    "invoicing reports.",
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
    }
}

private enum class RangeChoice { WEEK, MONTH }

private val RANGE_FORMAT: DateTimeFormatter = DateTimeFormatter.ofPattern("d MMM")
