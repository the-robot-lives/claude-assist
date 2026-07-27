package com.noizu.timely.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.foundation.text.KeyboardOptions
import com.noizu.timely.core.identity.Canon
import com.noizu.timely.ui.components.SectionHeader
import com.noizu.timely.ui.theme.Spacing
import java.time.Instant
import java.time.LocalDate
import java.time.LocalTime
import java.time.ZoneId

/**
 * Manual entry.
 *
 * Works with no network and no valid session. Nothing on this screen consults
 * the auth state, and the save button is never disabled because of it -- a time
 * tracker that will not let you record time while offline has failed at its one
 * job.
 */
@Composable
fun ManualEntryScreen(
    day: LocalDate,
    onSave: (
        title: String,
        client: String,
        project: String,
        ticket: String,
        start: Instant,
        end: Instant?,
        billable: Boolean,
        notes: String,
    ) -> Unit,
    onCancel: () -> Unit,
    modifier: Modifier = Modifier,
) {
    var title by remember { mutableStateOf("") }
    var client by remember { mutableStateOf("") }
    var project by remember { mutableStateOf("") }
    var ticket by remember { mutableStateOf("") }
    var startText by remember { mutableStateOf("09:00") }
    var endText by remember { mutableStateOf("10:00") }
    var billable by remember { mutableStateOf(true) }
    var notes by remember { mutableStateOf("") }

    val zone = ZoneId.systemDefault()
    val start = parseLocalTime(startText)?.let { day.atTime(it).atZone(zone).toInstant() }
    val end = parseLocalTime(endText)?.let { day.atTime(it).atZone(zone).toInstant() }

    val timesValid = start != null && (end == null || end.isAfter(start))
    val titleValid = title.isNotBlank()

    Column(
        modifier = modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(Spacing.card),
        verticalArrangement = Arrangement.spacedBy(Spacing.compact),
    ) {
        SectionHeader("New time entry", day.toString())

        OutlinedTextField(
            value = title,
            onValueChange = { title = it },
            label = { Text("What did you work on?") },
            modifier = Modifier.fillMaxWidth(),
            singleLine = true,
            isError = title.isNotEmpty() && !titleValid,
        )
        OutlinedTextField(
            value = client,
            onValueChange = { client = it },
            label = { Text("Client (optional)") },
            modifier = Modifier.fillMaxWidth(),
            singleLine = true,
        )
        OutlinedTextField(
            value = project,
            onValueChange = { project = it },
            label = { Text("Project (optional)") },
            modifier = Modifier.fillMaxWidth(),
            singleLine = true,
        )
        OutlinedTextField(
            value = ticket,
            onValueChange = { ticket = it },
            label = { Text("Ticket (optional)") },
            modifier = Modifier.fillMaxWidth(),
            singleLine = true,
        )

        // Shows the user the same normalization the id derivation uses, so
        // "Acme " and "acme" visibly resolve to one client instead of quietly
        // becoming two.
        if (!Canon.isBlank(project)) {
            Text(
                "Will attach to: ${listOf(client, project, ticket)
                    .filter { !Canon.isBlank(it) }
                    .joinToString(" / ") { Canon.canonOrNull(it).orEmpty() }}",
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }

        Row(horizontalArrangement = Arrangement.spacedBy(Spacing.base)) {
            OutlinedTextField(
                value = startText,
                onValueChange = { startText = it },
                label = { Text("Start") },
                modifier = Modifier.weight(1f),
                singleLine = true,
                isError = parseLocalTime(startText) == null,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
            )
            OutlinedTextField(
                value = endText,
                onValueChange = { endText = it },
                label = { Text("End") },
                modifier = Modifier.weight(1f),
                singleLine = true,
                isError = endText.isNotBlank() && parseLocalTime(endText) == null,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
            )
        }
        if (!timesValid) {
            Text(
                "Use HH:MM, and make the end later than the start.",
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.error,
            )
        }

        Row(
            Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text("Billable", style = MaterialTheme.typography.bodyLarge)
            Switch(checked = billable, onCheckedChange = { billable = it })
        }

        OutlinedTextField(
            value = notes,
            onValueChange = { notes = it },
            label = { Text("Notes") },
            modifier = Modifier.fillMaxWidth(),
            minLines = 3,
        )

        Row(horizontalArrangement = Arrangement.spacedBy(Spacing.base)) {
            Button(
                onClick = {
                    onSave(title, client, project, ticket, start!!, end, billable, notes)
                },
                // Disabled only for genuinely unusable input. Never for network
                // or session state.
                enabled = titleValid && timesValid,
                modifier = Modifier.weight(1f),
            ) { Text("Save entry") }
            OutlinedButton(onClick = onCancel, modifier = Modifier.weight(1f)) { Text("Cancel") }
        }

        Text(
            "Saved on this device immediately. It syncs when a connection and a " +
                "valid session are available.",
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
    }
}

/** Accepts "9:05", "09:05", "0905". Returns null rather than throwing on junk. */
internal fun parseLocalTime(raw: String): LocalTime? {
    val trimmed = raw.trim()
    if (trimmed.isEmpty()) return null
    val normalized = when {
        trimmed.contains(':') -> trimmed
        trimmed.length == 4 -> "${trimmed.take(2)}:${trimmed.drop(2)}"
        else -> return null
    }
    val parts = normalized.split(':')
    if (parts.size != 2) return null
    val hour = parts[0].toIntOrNull() ?: return null
    val minute = parts[1].toIntOrNull() ?: return null
    if (hour !in 0..23 || minute !in 0..59) return null
    return LocalTime.of(hour, minute)
}
