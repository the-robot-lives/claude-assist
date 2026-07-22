package com.noizu.billing

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            MaterialTheme {
                Surface(modifier = Modifier.fillMaxSize(), color = Color(0xFFEEF2EF)) {
                    BillingDashboard()
                }
            }
        }
    }
}

data class BillingInvoice(
    val number: String,
    val customer: String,
    val project: String,
    val status: String,
    val amount: String,
    val dueDate: String,
    val nextAction: String
)

data class ReadinessItem(
    val label: String,
    val state: String
)

data class PaymentRail(
    val label: String,
    val state: String
)

private val invoices = emptyList<BillingInvoice>()

private val readinessItems = listOf(
    ReadinessItem("Phoenix API", "Contract drafted"),
    ReadinessItem("PostgreSQL ledger", "Schema pending"),
    ReadinessItem("Stripe webhooks", "Not connected"),
    ReadinessItem("PayPal webhooks", "Not connected"),
    ReadinessItem("ACH processor", "Not connected"),
    ReadinessItem("PDF worker", "Not connected")
)

private val paymentRails = listOf(
    PaymentRail("Stripe", "Hosted links not connected"),
    PaymentRail("PayPal", "Checkout not connected"),
    PaymentRail("ACH", "Settlement rules pending")
)

@Composable
fun BillingDashboard() {
    Scaffold(
        bottomBar = {
            NavigationBar {
                NavigationBarItem(selected = true, onClick = {}, label = { Text("Dashboard") }, icon = {})
                NavigationBarItem(selected = false, onClick = {}, label = { Text("Invoices") }, icon = {})
                NavigationBarItem(selected = false, onClick = {}, label = { Text("Payments") }, icon = {})
            }
        }
    ) { padding ->
        LazyColumn(
            modifier = Modifier
                .padding(padding)
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            item {
                Text("Billing Noizu", style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Bold)
                Text("Bureau Signal mobile workspace", color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
            item {
                SummaryCard()
            }
            if (invoices.isEmpty()) {
                item {
                    EmptyCard(
                        title = "No live invoices",
                        body = "Connect the billing API and ledger before invoice review starts."
                    )
                }
            } else {
                invoices.forEach { invoice ->
                    item {
                        InvoiceCard(invoice)
                    }
                }
            }
            item {
                ReadinessCard()
            }
            item {
                PaymentRailsCard()
            }
        }
    }
}

@Composable
private fun SummaryCard() {
    Card(colors = CardDefaults.cardColors(containerColor = Color(0xFFFCFDFB))) {
        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                Metric("Outstanding", "Pending")
                Metric("Overdue", "Pending")
            }
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                Metric("Paid", "Pending")
                Metric("Risk", "Pending")
            }
        }
    }
}

@Composable
private fun Metric(label: String, value: String) {
    Column {
        Text(label, color = MaterialTheme.colorScheme.onSurfaceVariant)
        Text(value, style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
    }
}

@Composable
private fun EmptyCard(title: String, body: String) {
    Card(colors = CardDefaults.cardColors(containerColor = Color(0xFFFCFDFB))) {
        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
            Text(title, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
            Text(body, color = MaterialTheme.colorScheme.onSurfaceVariant)
            Button(onClick = {}) {
                Text("Create draft")
            }
            Button(onClick = {}) {
                Text("Record payment")
            }
        }
    }
}

@Composable
private fun ReadinessCard() {
    Card(colors = CardDefaults.cardColors(containerColor = Color(0xFFFCFDFB))) {
        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
            Text("Production connections", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
            readinessItems.forEach { item ->
                Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                    Text(item.label)
                    Text(item.state, fontWeight = FontWeight.SemiBold)
                }
            }
        }
    }
}

@Composable
private fun PaymentRailsCard() {
    Card(colors = CardDefaults.cardColors(containerColor = Color(0xFFFCFDFB))) {
        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
            Text("Payment methods", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
            paymentRails.forEach { rail ->
                Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                    Text(rail.label)
                    Text(rail.state, fontWeight = FontWeight.SemiBold)
                }
            }
        }
    }
}

@Composable
private fun InvoiceCard(invoice: BillingInvoice) {
    Card(colors = CardDefaults.cardColors(containerColor = Color(0xFFFCFDFB))) {
        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                Text(invoice.number, fontWeight = FontWeight.Bold)
                Text(invoice.amount, fontWeight = FontWeight.Bold)
            }
            Text(invoice.customer)
            Text(invoice.project, color = MaterialTheme.colorScheme.onSurfaceVariant)
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                Text(invoice.status)
                Text(invoice.dueDate)
            }
            Button(onClick = {}) {
                Text(invoice.nextAction)
            }
            Button(onClick = {}) {
                Text("Send invoice")
            }
            Button(onClick = {}) {
                Text("Record payment")
            }
        }
    }
}
