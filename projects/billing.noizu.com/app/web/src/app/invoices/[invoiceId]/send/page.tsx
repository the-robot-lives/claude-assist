import Link from "next/link";
import { AppShell } from "@/components/app-shell";
import { paymentMethods } from "@/lib/billing-data";

type PageProps = {
  params: Promise<{ invoiceId: string }>;
};

export default async function SendInvoicePage({ params }: PageProps) {
  const { invoiceId } = await params;

  return (
    <AppShell>
      <header className="topbar">
        <div>
          <p className="eyebrow">Send invoice</p>
          <h1>Review delivery before sending</h1>
        </div>
        <Link className="button ghost" href={`/invoices/${invoiceId}`}>
          View invoice
        </Link>
      </header>

      <section className="workspace-grid">
        <article className="panel offset-panel">
          <form className="form-grid">
            <label>
              Recipient email
              <input type="email" placeholder="accounts-payable@customer.com" />
            </label>
            <label>
              Email subject
              <input placeholder="Invoice subject" />
            </label>
            <label>
              Message
              <textarea placeholder="Short payment note" rows={7} />
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
              </select>
            </label>
            <button className="button primary" type="button">
              Queue send
            </button>
          </form>
        </article>

        <aside className="panel signal-panel">
          <p className="eyebrow">Send gate</p>
          <h2>External delivery is blocked</h2>
          <div className="notice-stack">
            <p className="notice danger">PDF worker must render the final invoice before delivery.</p>
            <p className="notice danger">At least one payment method must be connected before payment links are exposed.</p>
            <p className="notice warning">Human approval is required before the email leaves the workspace.</p>
          </div>
        </aside>
      </section>
    </AppShell>
  );
}
