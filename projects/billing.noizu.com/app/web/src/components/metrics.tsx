import { formatMoney, receivablesSummary } from "@/lib/billing-data";

function formatMetricMoney(value: typeof receivablesSummary.outstanding) {
  return value ? formatMoney(value) : "Pending";
}

function formatMetricCount(value: number | null) {
  return value === null ? "Pending" : value.toString();
}

export function Metrics() {
  return (
    <section className="metrics" aria-label="Receivables summary">
      <article className="metric">
        <span>Outstanding</span>
        <strong>{formatMetricMoney(receivablesSummary.outstanding)}</strong>
        <small>{formatMetricCount(receivablesSummary.openInvoiceCount)} open invoices</small>
      </article>
      <article className="metric">
        <span>Overdue</span>
        <strong>{formatMetricMoney(receivablesSummary.overdue)}</strong>
        <small>No live ledger connected</small>
      </article>
      <article className="metric">
        <span>Paid this month</span>
        <strong>{formatMetricMoney(receivablesSummary.paidThisMonth)}</strong>
        <small>Awaiting payment sync</small>
      </article>
      <article className="metric">
        <span>Collection risk</span>
        <strong>{formatMetricCount(receivablesSummary.collectionRiskCount)}</strong>
        <small>Agent rules not armed</small>
      </article>
    </section>
  );
}
