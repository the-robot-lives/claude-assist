import Link from "next/link";
import { AppShell } from "@/components/app-shell";
import { EmptyState } from "@/components/empty-state";
import { invoices, paymentMethods } from "@/lib/billing-data";

type PageProps = {
  params: Promise<{ invoiceId: string }>;
};

export default async function InvoiceViewPage({ params }: PageProps) {
  const { invoiceId } = await params;
  const invoice = invoices.find((candidate) => candidate.id === invoiceId);

  return (
    <AppShell>
      <header className="topbar">
        <div>
          <p className="eyebrow">Invoice</p>
          <h1>{invoice ? invoice.number : "Invoice detail"}</h1>
        </div>
        <div className="actions">
          <Link className="button ghost" href={`/invoices/${invoiceId}/send`}>
            Send invoice
          </Link>
          <Link className="button primary" href="/payments/record">
            Record payment
          </Link>
        </div>
      </header>

      {invoice ? (
        <section className="workspace-grid">
          <article className="panel">
            <p className="eyebrow">Ledger view</p>
            <h2>{invoice.customer}</h2>
            <div className="detail-card">
              <div className="detail-total">
                <span>Status</span>
                <strong>{invoice.status.replace("_", " ")}</strong>
              </div>
              <div className="detail-total">
                <span>Due</span>
                <strong>{invoice.dueDate}</strong>
              </div>
            </div>
          </article>
          <aside className="panel">
            <p className="eyebrow">Payment methods</p>
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
      ) : (
        <section className="panel offset-panel">
          <EmptyState
            eyebrow="Invoice unavailable"
            title="No invoice record exists for this route yet."
            body="The detail shell is ready for live invoice data, send actions, payment links, and payment history once the API is wired."
            actionHref="/invoices"
            actionLabel="Back to invoices"
          />
        </section>
      )}
    </AppShell>
  );
}
