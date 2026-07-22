import Link from "next/link";
import { AppShell } from "@/components/app-shell";
import { EmptyState } from "@/components/empty-state";
import { InvoiceList } from "@/components/invoice-list";
import { Metrics } from "@/components/metrics";
import { auditEvents, customers, integrationReadiness, invoices } from "@/lib/billing-data";

export default function DashboardPage() {
  return (
    <AppShell>
      <header className="topbar">
        <div>
          <p className="eyebrow">Bureau Signal</p>
          <h1>Noizu Operations Billing</h1>
        </div>
        <div className="actions">
          <Link className="button ghost" href="/apps">Review integrations</Link>
          <Link className="button primary" href="/invoices/new">New invoice</Link>
        </div>
      </header>

      <Metrics />

      <section className="workspace-grid">
        <article className="panel">
          <div className="panel-heading">
            <div>
              <p className="eyebrow">Invoice queue</p>
              <h2>Prioritized work</h2>
            </div>
          </div>
          <InvoiceList invoices={invoices} />
        </article>

        <aside className="panel signal-panel" aria-label="Billing readiness">
          <p className="eyebrow">Readiness</p>
          <h2>Production connections</h2>
          <div className="integration-list">
            {integrationReadiness.map((item) => (
              <div className="status-line" data-tone={item.tone} key={item.label}>
                <span>{item.label}</span>
                <strong>{item.state}</strong>
              </div>
            ))}
          </div>
        </aside>

        <article className="panel">
          <div className="panel-heading">
            <div>
              <p className="eyebrow">Customers</p>
              <h2>Account pressure</h2>
            </div>
          </div>
          {customers.length === 0 ? (
            <EmptyState
              eyebrow="No customers"
              title="Customer pressure appears after account import."
              body="Add a customer or connect CRM/accounting records to populate billing status, balances, and risk."
              actionHref="/customers/new"
              actionLabel="Create customer"
            />
          ) : (
            <div className="list">
              {customers.map((customer) => (
                <Link className="record-row" href={`/customers?customer=${customer.id}`} key={customer.id}>
                  <strong>{customer.name}</strong>
                  <span>{customer.status}</span>
                  <span className={`badge ${customer.risk}`}>{customer.risk}</span>
                </Link>
              ))}
            </div>
          )}
        </article>

        <article className="panel">
          <div className="panel-heading">
            <div>
              <p className="eyebrow">Audit trail</p>
              <h2>Recent financial events</h2>
            </div>
          </div>
          {auditEvents.length === 0 ? (
            <EmptyState
              eyebrow="No events"
              title="Audit trail starts with the first billing mutation."
              body="Invoice creation, approvals, payment events, and agent actions will appear here once connected."
            />
          ) : (
            <ol className="audit-list">
              {auditEvents.map((event) => (
                <li key={event.id}>
                  <span>{event.event}</span>
                  <time>{event.occurredAt}</time>
                </li>
              ))}
            </ol>
          )}
        </article>
      </section>
    </AppShell>
  );
}
