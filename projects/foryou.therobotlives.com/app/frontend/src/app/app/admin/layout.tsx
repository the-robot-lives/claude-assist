"use client";

import { useEffect } from "react";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { useAuth } from "@/context/auth";

const NAV_LINKS = [
  { href: "/app/admin/users", label: "Users" },
  { href: "/app/admin/orgs", label: "Orgs" },
];

const PLACEHOLDER_LINKS = [
  { label: "Lists", badge: "soon" },
  { label: "Inquiries", badge: "soon" },
];

export default function AdminLayout({ children }: { children: React.ReactNode }) {
  const { user, loading } = useAuth();
  const router = useRouter();
  const pathname = usePathname();

  useEffect(() => {
    if (loading) return;
    if (!user) {
      router.replace("/login");
    } else if (!user.admin) {
      router.replace("/app");
    }
  }, [loading, user, router]);

  if (loading || !user || !user.admin) {
    return <p className="sg-admin-loading">Loading...</p>;
  }

  return (
    <div className="sg-admin-shell">
      <aside className="sg-admin-sidebar">
        <p className="sg-admin-sidebar__title">Admin</p>
        <nav>
          <ul className="sg-admin-nav">
            {NAV_LINKS.map((link) => {
              const active = pathname === link.href || pathname.startsWith(link.href + "/");
              return (
                <li key={link.href}>
                  <Link
                    href={link.href}
                    className={
                      "sg-admin-nav-link" + (active ? " sg-admin-nav-link--active" : "")
                    }
                  >
                    {link.label}
                  </Link>
                </li>
              );
            })}
            {PLACEHOLDER_LINKS.map((link) => (
              <li key={link.label}>
                <span className="sg-admin-nav-link sg-admin-nav-link--disabled">
                  {link.label}
                  <span className="sg-admin-nav-link-badge">{link.badge}</span>
                </span>
              </li>
            ))}
          </ul>
        </nav>
      </aside>
      <main className="sg-admin-main">{children}</main>
    </div>
  );
}
