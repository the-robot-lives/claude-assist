import Link from "next/link";
import { AppShell } from "@/components/app-shell";
import { EmptyState } from "@/components/empty-state";
import { paymentMethods, payments } from "@/lib/billing-data";

export default function PaymentsPage() {
  return (
    <AppShell>
      <header className="topbar">
        <div>
          <p className="eyebrow">Payments</p>
          <h1>Payment operations</h1>
        </div>
        <div className="actions">
          <Link className="button ghost" href="/payments/methods">Payment methods</Link>
          <Link className="button primary" href="/payments/record">Record payment</Link>
        </div>
      </header>

      <section className="workspace-grid">
        <article className="panel offset-panel">
          <div className="panel-heading">
            <div>
              <p className="eyebrow">Payment history</p>
              <h2>Recorded payments</h2>
            </div>
          </div>
          {payments.length === 0 ? (
            <EmptyState
              eyebrow="No payments"
              title="No payment events have been recorded."
              body="Stripe, PayPal, ACH, and manual payment records will appear here after the ledger API is connected."
              actionHref="/payments/record"
              actionLabel="Record payment"
            />
          ) : null}
        </article>

        <aside className="panel signal-panel">
          <p className="eyebrow">Rails</p>
          <h2>Payment method readiness</h2>
          <div className="integration-list">
            {paymentMethods.map((method) => (
              <div className="status-line" data-tone="danger" key={method.provider}>
                <span>{method.label}</span>
                <strong>{method.state.replace("_", " ")}</strong>
              </div>
            ))}
          </div>
        </aside>
      </section>
    </AppShell>
  );
}
