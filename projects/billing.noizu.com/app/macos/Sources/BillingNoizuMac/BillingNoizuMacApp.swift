import SwiftUI

@main
struct BillingNoizuMacApp: App {
    var body: some Scene {
        WindowGroup {
            ReceivablesCockpitView()
        }
        .commands {
            CommandMenu("Billing") {
                Button("New Invoice") {}
                    .keyboardShortcut("n")
                Button("Record Payment") {}
                    .keyboardShortcut("p")
                Button("Refresh Receivables") {}
                    .keyboardShortcut("r")
            }
        }

        MenuBarExtra("Billing Noizu", systemImage: "checklist.checked") {
            MenuBarCollectionsView()
        }
        .menuBarExtraStyle(.window)
    }
}

struct MacInvoice: Identifiable, Hashable {
    let id: String
    let number: String
    let customer: String
    let status: String
    let amount: String
    let dueDate: String
}

struct MacReadinessItem: Identifiable {
    let id = UUID()
    let label: String
    let state: String
}

struct MacPaymentRail: Identifiable {
    let id = UUID()
    let label: String
    let state: String
}

private let macInvoices: [MacInvoice] = []

private let macReadiness = [
    MacReadinessItem(label: "Phoenix API", state: "Contract drafted"),
    MacReadinessItem(label: "PostgreSQL ledger", state: "Schema pending"),
    MacReadinessItem(label: "Stripe webhooks", state: "Not connected"),
    MacReadinessItem(label: "PayPal webhooks", state: "Not connected"),
    MacReadinessItem(label: "ACH processor", state: "Not connected"),
    MacReadinessItem(label: "PDF worker", state: "Not connected")
]

private let macPaymentRails = [
    MacPaymentRail(label: "Stripe", state: "Hosted links not connected"),
    MacPaymentRail(label: "PayPal", state: "Checkout not connected"),
    MacPaymentRail(label: "ACH", state: "Settlement rules pending")
]

struct ReceivablesCockpitView: View {
    @State private var selectedInvoice: MacInvoice?
    @State private var selection = "Invoices"

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Text("Dashboard").tag("Dashboard")
                Text("Invoices").tag("Invoices")
                Text("Customers").tag("Customers")
                Text("Payments").tag("Payments")
                Text("Reports").tag("Reports")
                Text("Audit").tag("Audit")
            }
            .navigationTitle("Billing")
        } content: {
            if macInvoices.isEmpty {
                ContentUnavailableView(
                    "No live invoices",
                    systemImage: "tray",
                    description: Text("Connect the billing API and ledger before the desktop queue is populated.")
                )
                .navigationTitle(selection)
            } else {
                List(macInvoices, selection: $selectedInvoice) { invoice in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(invoice.number).font(.headline)
                        Text(invoice.customer).foregroundStyle(.secondary)
                    }
                    .tag(invoice)
                }
                .navigationTitle(selection)
            }
        } detail: {
            if let selectedInvoice {
                InvoiceInspector(invoice: selectedInvoice)
            } else {
                ReadinessInspector()
            }
        }
        .frame(minWidth: 980, minHeight: 620)
        .toolbar {
            ToolbarItemGroup {
                Button("New Invoice", systemImage: "plus") {}
                Button("Record Payment", systemImage: "creditcard.and.123") {}
                Button("Export", systemImage: "square.and.arrow.down") {}
                Button("Inspector", systemImage: "sidebar.right") {}
            }
        }
        .tint(Color(red: 0.0, green: 0.49, blue: 0.45))
    }
}

struct InvoiceInspector: View {
    let invoice: MacInvoice

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(invoice.number)
                .font(.largeTitle.bold())
            Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 10) {
                GridRow { Text("Customer"); Text(invoice.customer).bold() }
                GridRow { Text("Status"); Text(invoice.status).bold() }
                GridRow { Text("Amount"); Text(invoice.amount).bold() }
                GridRow { Text("Due"); Text(invoice.dueDate).bold() }
            }
            Divider()
            Button("Open payment history") {}
            Button("Send invoice") {}
            Button("Record payment") {}
            Button("Approve follow-up draft") {}
            Spacer()
        }
        .padding(28)
        .navigationTitle(invoice.number)
    }
}

struct ReadinessInspector: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Production connections")
                .font(.largeTitle.bold())
            Text("The cockpit is intentionally empty until live billing systems are connected.")
                .foregroundStyle(.secondary)
            Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 12) {
                ForEach(macReadiness) { item in
                    GridRow {
                        Text(item.label)
                        Text(item.state).bold()
                    }
                }
            }
            Divider()
            Text("Payment rails")
                .font(.headline)
            Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 12) {
                ForEach(macPaymentRails) { rail in
                    GridRow {
                        Text(rail.label)
                        Text(rail.state).bold()
                    }
                }
            }
            Spacer()
        }
        .padding(28)
        .navigationTitle("Readiness")
    }
}

struct MenuBarCollectionsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Collections")
                .font(.headline)
            LabeledContent("Receivables", value: "Pending")
            LabeledContent("At risk", value: "Pending")
            LabeledContent("Payments", value: "Pending")
            LabeledContent("Rails", value: "Stripe, PayPal, ACH pending")
            Divider()
            Button("Open receivables cockpit") {}
        }
        .padding()
        .frame(width: 280)
    }
}

#Preview {
    ReceivablesCockpitView()
}
