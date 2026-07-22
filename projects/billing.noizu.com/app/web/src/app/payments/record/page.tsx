import Link from "next/link";
import type { Route } from "next";
import { AppShell } from "@/components/app-shell";
import { paymentMethods } from "@/lib/billing-data";

export default function RecordPaymentPage() {
  return (
    <AppShell>
      <header className="topbar">
        <div>
          <p className="eyebrow">Record payment</p>
          <h1>Apply payment to invoice</h1>
        </div>
        <Link className="button ghost" href={"/payments/methods" as Route}>
          Payment methods
        </Link>
      </header>

      <section className="workspace-grid">
        <article className="panel offset-panel">
          <form className="form-grid">
            <label>
              Invoice ID
              <input placeholder="Invoice reference" />
            </label>
            <label>
              Payment rail
              <select defaultValue="">
                <option value="" disabled>
                  Select payment rail
                </option>
                {paymentMethods.map((method) => (
                  <option key={method.provider} value={method.provider}>
                    {method.label}
                  </option>
                ))}
                <option value="manual">Manual adjustment</option>
              </select>
            </label>
            <label>
              Amount
              <input inputMode="decimal" placeholder="Amount received" />
            </label>
            <label>
              Received date
              <input type="date" />
            </label>
            <label>
              Processor reference
              <input placeholder="Transaction, trace, or confirmation ID" />
            </label>
            <label>
              Internal note
              <textarea placeholder="Optional reconciliation note" rows={5} />
            </label>
            <button className="button primary" type="button">
              Queue payment record
            </button>
          </form>
        </article>

        <aside className="panel signal-panel">
          <p className="eyebrow">Ledger guardrails</p>
          <h2>Payment records are append-only</h2>
          <div className="notice-stack">
            <p className="notice warning">Partial payments must keep the invoice balance visible.</p>
            <p className="notice danger">ACH references need settlement confirmation before marking paid.</p>
            <p className="notice info">Stripe and PayPal records should reconcile against webhook events when available.</p>
          </div>
        </aside>
      </section>
    </AppShell>
  );
}
