import { AppShell } from "@/components/app-shell";

const platforms = [
  ["Web app", "Canonical full workspace", "Responsive dashboard, deep links, full invoice/customer/payment/report workflows"],
  ["iOS", "Mobile approval companion", "SwiftUI review flows, push notifications, safe approvals, offline read cache"],
  ["Android", "Mobile approval companion", "Jetpack Compose review flows, notification channels, app links, offline read cache"],
  ["macOS", "Desktop finance cockpit", "Sidebar/detail workbench, multi-window review, keyboard commands, menu bar status"],
] as const;

export default function AppsPage() {
  return (
    <AppShell>
      <header className="topbar">
        <div>
          <p className="eyebrow">Apps</p>
          <h1>Platform surfaces</h1>
        </div>
      </header>
      <section className="platform-grid" style={{ marginTop: 28 }}>
        {platforms.map(([name, role, scope]) => (
          <article className="platform-card" key={name}>
            <p className="eyebrow">{role}</p>
            <h2>{name}</h2>
            <p className="muted">{scope}</p>
          </article>
        ))}
      </section>
    </AppShell>
  );
}
