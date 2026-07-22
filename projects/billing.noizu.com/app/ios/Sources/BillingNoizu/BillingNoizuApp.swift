import SwiftUI

@main
struct BillingNoizuApp: App {
    var body: some Scene {
        WindowGroup {
            BillingDashboardView()
        }
    }
}

struct BillingInvoice: Identifiable, Hashable {
    let id: String
    let number: String
    let customer: String
    let project: String
    let status: String
    let amount: String
    let dueDate: String
    let nextAction: String
}

struct ReadinessItem: Identifiable {
    let id = UUID()
    let label: String
    let state: String
    let systemImage: String
}

struct PaymentRail: Identifiable {
    let id = UUID()
    let label: String
    let state: String
}

private let invoices: [BillingInvoice] = []

private let readinessItems = [
    ReadinessItem(label: "Phoenix API", state: "Contract drafted", systemImage: "curlybraces"),
    ReadinessItem(label: "PostgreSQL ledger", state: "Schema pending", systemImage: "cylinder.split.1x2"),
    ReadinessItem(label: "Stripe webhooks", state: "Not connected", systemImage: "bolt.horizontal.circle"),
    ReadinessItem(label: "PayPal webhooks", state: "Not connected", systemImage: "p.circle"),
    ReadinessItem(label: "ACH processor", state: "Not connected", systemImage: "building.columns"),
    ReadinessItem(label: "PDF worker", state: "Not connected", systemImage: "doc.richtext")
]

private let paymentRails = [
    PaymentRail(label: "Stripe", state: "Hosted links not connected"),
    PaymentRail(label: "PayPal", state: "Checkout not connected"),
    PaymentRail(label: "ACH", state: "Settlement rules pending")
]

struct BillingDashboardView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    SummaryGrid()
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }

                Section("Invoice queue") {
                    if invoices.isEmpty {
                        ContentUnavailableView(
                            "No live invoices",
                            systemImage: "tray",
                            description: Text("Connect the billing API and ledger before invoice work starts.")
                        )
                    } else {
                        ForEach(invoices) { invoice in
                            NavigationLink(value: invoice) {
                                InvoiceRow(invoice: invoice)
                            }
                        }
                    }
                }

                Section("Production readiness") {
                    ForEach(readinessItems) { item in
                        LabeledContent {
                            Text(item.state)
                                .fontWeight(.semibold)
                        } label: {
                            Label(item.label, systemImage: item.systemImage)
                        }
                    }
                }

                Section("Payment methods") {
                    ForEach(paymentRails) { rail in
                        LabeledContent(rail.label, value: rail.state)
                    }
                    Button {
                    } label: {
                        Label("Record payment", systemImage: "creditcard.and.123")
                    }
                }

                Section("Mobile actions") {
                    Label("Invoice send review pending", systemImage: "paperplane")
                    Label("Push approval hooks pending", systemImage: "bell.badge")
                    Label("Deep links use canonical web URLs", systemImage: "link")
                    Label("Offline records remain read-only", systemImage: "icloud.slash")
                }
            }
            .navigationTitle("Billing Noizu")
            .navigationDestination(for: BillingInvoice.self) { invoice in
                InvoiceDetailView(invoice: invoice)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {} label: {
                        Label("New invoice", systemImage: "plus")
                    }
                }
            }
        }
        .tint(Color(red: 0.0, green: 0.49, blue: 0.45))
    }
}

struct SummaryGrid: View {
    private let metrics = [
        ("Outstanding", "Pending"),
        ("Overdue", "Pending"),
        ("Paid", "Pending"),
        ("Risk", "Pending")
    ]

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(metrics, id: \.0) { metric in
                VStack(alignment: .leading, spacing: 6) {
                    Text(metric.0)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(metric.1)
                        .font(.title2.bold())
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 6))
            }
        }
        .padding(.vertical, 8)
    }
}

struct InvoiceRow: View {
    let invoice: BillingInvoice

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(invoice.number).font(.headline)
                Spacer()
                Text(invoice.amount).font(.headline)
            }
            Text(invoice.customer)
            HStack {
                Text(invoice.status)
                Spacer()
                Text(invoice.dueDate)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}

struct InvoiceDetailView: View {
    let invoice: BillingInvoice

    var body: some View {
        Form {
            Section("Invoice") {
                LabeledContent("Number", value: invoice.number)
                LabeledContent("Customer", value: invoice.customer)
                LabeledContent("Project", value: invoice.project)
                LabeledContent("Status", value: invoice.status)
                LabeledContent("Amount", value: invoice.amount)
                LabeledContent("Due", value: invoice.dueDate)
            }

            Section("Approval") {
                Button(invoice.nextAction) {}
                Button("Send invoice") {}
                Button("Record payment") {}
                Button("Open web workspace") {}
            }
        }
        .navigationTitle(invoice.number)
    }
}

#Preview {
    BillingDashboardView()
}
