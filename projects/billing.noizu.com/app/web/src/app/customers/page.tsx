import { AppShell } from "@/components/app-shell";
import { EmptyState } from "@/components/empty-state";
import { customers, formatMoney } from "@/lib/billing-data";

export default function CustomersPage() {
  return (
    <AppShell>
      <header className="topbar">
        <div>
          <p className="eyebrow">Customers</p>
          <h1>Customer billing pressure</h1>
        </div>
        <a className="button primary" href="/customers/new">New customer</a>
      </header>
      <section className="panel" style={{ marginTop: 28 }}>
        {customers.length === 0 ? (
          <EmptyState
            eyebrow="No customers"
            title="Customer records have not been imported."
            body="Create the first customer or connect the source of truth before showing balances and risk scores."
            actionHref="/customers/new"
            actionLabel="Create customer"
          />
        ) : (
          <div className="list">
            {customers.map((customer) => (
              <a className="record-row" href={`/customers?customer=${customer.id}`} key={customer.id}>
                <span>
                  <strong>{customer.name}</strong>
                  <br />
                  <span className="muted">{customer.status}</span>
                </span>
                <span>{formatMoney(customer.balance)}</span>
                <span className={`badge ${customer.risk}`}>{customer.risk}</span>
              </a>
            ))}
          </div>
        )}
      </section>
    </AppShell>
  );
}
