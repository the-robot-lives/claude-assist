import { AppShell } from "@/components/app-shell";

export default function NewCustomerPage() {
  return (
    <AppShell>
      <header className="topbar">
        <div>
          <p className="eyebrow">Customers</p>
          <h1>Create customer</h1>
        </div>
      </header>
      <section className="panel" style={{ marginTop: 28 }}>
        <form className="form-grid">
          <label>
            Company
            <input placeholder="Company name" />
          </label>
          <label>
            Billing email
            <input placeholder="billing@company.com" />
          </label>
          <label>
            Payment terms
            <input placeholder="Net terms" />
          </label>
          <button className="button primary" type="button">Create customer</button>
        </form>
      </section>
    </AppShell>
  );
}
