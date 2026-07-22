import Link from "next/link";
import type { Route } from "next";
import type { ReactNode } from "react";

const navItems = [
  { href: "/", label: "Dashboard" },
  { href: "/invoices", label: "Invoices" },
  { href: "/payments", label: "Payments" },
  { href: "/customers", label: "Customers" },
  { href: "/apps", label: "Apps" },
  { href: "/audit", label: "Audit" },
] as const;

export function AppShell({ children }: { children: ReactNode }) {
  return (
    <div className="app-shell">
      <aside className="sidebar" aria-label="Billing navigation">
        <Link className="brand" href="/" aria-label="Billing Noizu dashboard">
          <span className="brand-mark" aria-hidden="true">BN</span>
          <span>Billing Noizu</span>
        </Link>
        <nav className="nav">
          {navItems.map((item) => (
            <Link key={item.href} href={item.href as Route}>
              {item.label}
            </Link>
          ))}
        </nav>
      </aside>
      <main>{children}</main>
    </div>
  );
}
