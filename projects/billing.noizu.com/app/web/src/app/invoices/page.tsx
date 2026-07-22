import { AppShell } from "@/components/app-shell";
import { InvoiceList } from "@/components/invoice-list";
import { Metrics } from "@/components/metrics";
import { invoices } from "@/lib/billing-data";

export default function InvoicesPage() {
  return (
    <AppShell>
      <header className="topbar">
        <div>
          <p className="eyebrow">Invoices</p>
          <h1>Invoice operations</h1>
        </div>
        <a className="button primary" href="/invoices/new">New invoice</a>
      </header>
      <Metrics />
      <section className="panel" style={{ marginTop: 16 }}>
        <div className="panel-heading">
          <div>
            <p className="eyebrow">Queue</p>
            <h2>All active invoices</h2>
          </div>
        </div>
        <InvoiceList invoices={invoices} />
      </section>
    </AppShell>
  );
}
