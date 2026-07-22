import { AppShell } from "@/components/app-shell";

export default function NewInvoicePage() {
  return (
    <AppShell>
      <header className="topbar">
        <div>
          <p className="eyebrow">Invoices</p>
          <h1>Create draft invoice</h1>
        </div>
      </header>
      <section className="panel" style={{ marginTop: 28 }}>
        <form className="form-grid">
          <label>
            Customer
            <input placeholder="Customer name" />
          </label>
          <label>
            Service period
            <input placeholder="Service period" />
          </label>
          <label>
            Amount
            <input inputMode="decimal" placeholder="Amount" />
          </label>
          <button className="button primary" type="button">Create draft</button>
        </form>
      </section>
    </AppShell>
  );
}
