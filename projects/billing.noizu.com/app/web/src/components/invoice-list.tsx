import Link from "next/link";
import { formatMoney, type Invoice } from "@/lib/billing-data";
import { EmptyState } from "./empty-state";

export function InvoiceList({ invoices }: { invoices: Invoice[] }) {
  if (invoices.length === 0) {
    return (
      <EmptyState
        eyebrow="No live invoices"
        title="Connect the ledger before invoice work starts."
        body="The queue is intentionally empty until the Phoenix billing API and PostgreSQL ledger are wired into this surface."
        actionHref="/invoices/new"
        actionLabel="Create draft"
      />
    );
  }

  return (
    <div className="list">
      {invoices.map((invoice) => (
        <Link className="invoice-row" href={`/invoices?invoice=${invoice.id}`} key={invoice.id}>
          <span>
            <strong>{invoice.number}</strong>
            <br />
            <span className="muted">{invoice.customer}</span>
          </span>
          <span>{formatMoney(invoice.total)}</span>
          <span>{invoice.dueDate}</span>
          <span className={`badge ${invoice.status}`}>{invoice.status.replace("_", " ")}</span>
        </Link>
      ))}
    </div>
  );
}
