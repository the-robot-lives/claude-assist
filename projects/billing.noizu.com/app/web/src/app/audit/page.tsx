import { AppShell } from "@/components/app-shell";
import { EmptyState } from "@/components/empty-state";
import { auditEvents } from "@/lib/billing-data";

export default function AuditPage() {
  return (
    <AppShell>
      <header className="topbar">
        <div>
          <p className="eyebrow">Audit</p>
          <h1>Financial event trail</h1>
        </div>
      </header>
      <section className="panel" style={{ marginTop: 28 }}>
        {auditEvents.length === 0 ? (
          <EmptyState
            eyebrow="No events"
            title="No billing events have been recorded."
            body="The immutable event trail will populate when invoices, payments, approvals, or agent actions are written."
          />
        ) : (
          <ol className="audit-list">
            {auditEvents.map((event) => (
              <li key={event.id}>
                <span>
                  <strong>{event.event}</strong>
                  <br />
                  <span className="muted">{event.actor}</span>
                </span>
                <time>{event.occurredAt}</time>
              </li>
            ))}
          </ol>
        )}
      </section>
    </AppShell>
  );
}
