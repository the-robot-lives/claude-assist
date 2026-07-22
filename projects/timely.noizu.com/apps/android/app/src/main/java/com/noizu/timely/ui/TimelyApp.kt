package com.noizu.timely.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Divider
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.noizu.timely.data.TimelyFixtures
import com.noizu.timely.data.TimelyInterval

@Composable
fun TimelyApp() {
    var paused by remember { mutableStateOf(false) }

    LazyColumn(
        modifier = Modifier
            .background(Color(0xFFFAFAF7))
            .padding(18.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp)
    ) {
        item {
            Header(paused = paused, onToggle = { paused = !paused })
        }
        item {
            SummaryGrid()
        }
        item {
            SectionTitle("Daily timeline", "Review intervals, idle gaps, and confidence")
        }
        items(TimelyFixtures.intervals) { interval ->
            IntervalRow(interval)
        }
        item {
            PrivacyCard()
        }
    }
}

@Composable
private fun Header(paused: Boolean, onToggle: () -> Unit) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column {
            Text("Timely", fontSize = 32.sp, fontWeight = FontWeight.Bold)
            Text(
                if (paused) "Capture paused" else "Mobile review companion",
                color = Color(0xFF647067)
            )
        }
        Button(onClick = onToggle) {
            Text(if (paused) "Resume" else "Pause")
        }
    }
}

@Composable
private fun SummaryGrid() {
    val summary = TimelyFixtures.summary
    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
        Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            MetricCard("Reviewed", "%.1f".format(summary.reviewedHours), Modifier.weight(1f))
            MetricCard("Billable", "%.2f".format(summary.billableHours), Modifier.weight(1f))
        }
        Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            MetricCard("Confidence", "${summary.confidence}%", Modifier.weight(1f))
            MetricCard("Prompts", summary.unresolvedPrompts.toString(), Modifier.weight(1f))
        }
    }
}

@Composable
private fun MetricCard(label: String, value: String, modifier: Modifier = Modifier) {
    Card(
        modifier = modifier,
        shape = RoundedCornerShape(8.dp),
        colors = CardDefaults.cardColors(containerColor = Color.White)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(label, color = Color(0xFF647067), fontSize = 13.sp)
            Text(value, fontSize = 28.sp, fontWeight = FontWeight.SemiBold)
        }
    }
}

@Composable
private fun SectionTitle(title: String, detail: String) {
    Column(modifier = Modifier.padding(top = 10.dp)) {
        Text(title, fontSize = 22.sp, fontWeight = FontWeight.SemiBold)
        Text(detail, color = Color(0xFF647067))
    }
}

@Composable
private fun IntervalRow(interval: TimelyInterval) {
    Card(
        shape = RoundedCornerShape(8.dp),
        colors = CardDefaults.cardColors(containerColor = Color.White)
    ) {
        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(interval.task, fontWeight = FontWeight.SemiBold)
                Text("${interval.confidence}%", color = Color(0xFF2563EB))
            }
            Text("${interval.start}-${interval.end} / ${interval.project}", color = Color(0xFF647067))
            Text(interval.state, color = Color(0xFF0F9F6E), fontSize = 13.sp)
        }
    }
}

@Composable
private fun PrivacyCard() {
    val policy = TimelyFixtures.policy
    Card(
        shape = RoundedCornerShape(8.dp),
        colors = CardDefaults.cardColors(containerColor = Color.White)
    ) {
        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
            Text("Privacy policy", fontSize = 22.sp, fontWeight = FontWeight.SemiBold)
            Divider()
            Text("Screenshots every ${policy.screenshotIntervalMinutes} minutes")
            Text("Local-only screenshots: ${if (policy.localOnlyScreenshots) "enabled" else "disabled"}")
            Text("Retention: ${policy.retentionDays} days")
            Text("Excluded apps: ${policy.excludedApps.joinToString()}")
        }
    }
}

