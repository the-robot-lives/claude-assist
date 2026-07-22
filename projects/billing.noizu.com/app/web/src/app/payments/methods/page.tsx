import Link from "next/link";
import { AppShell } from "@/components/app-shell";
import { paymentMethods } from "@/lib/billing-data";

export default function PaymentMethodsPage() {
  return (
    <AppShell>
      <header className="topbar">
        <div>
          <p className="eyebrow">Payment methods</p>
          <h1>Configure payment rails</h1>
        </div>
        <Link className="button primary" href="/payments/record">
          Record payment
        </Link>
      </header>

      <section className="method-grid">
        {paymentMethods.map((method) => (
          <article className="method-card" data-provider={method.provider} key={method.provider}>
            <p className="eyebrow">{method.provider}</p>
            <h2>{method.label}</h2>
            <p className="muted">{method.description}</p>
            <div className="detail-total">
              <span>Status</span>
              <strong>{method.state.replace("_", " ")}</strong>
            </div>
            <form className="form-grid compact-form">
              <label>
                Public label
                <input placeholder={`${method.label} display label`} />
              </label>
              <label>
                Webhook endpoint
                <input placeholder="https://billing.noizu.com/api/webhooks/provider" />
              </label>
              <button className="button primary" type="button">
                Save configuration
              </button>
            </form>
          </article>
        ))}
      </section>
    </AppShell>
  );
}
