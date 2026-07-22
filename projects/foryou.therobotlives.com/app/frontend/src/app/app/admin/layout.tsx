"use client";

import { useEffect } from "react";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { useAuth } from "@/context/auth";

const NAV_LINKS = [
  { href: "/app/admin", label: "Dashboard", exact: true },
  { href: "/app/admin/services", label: "Services" },
  { href: "/app/admin/inquiries", label: "Inquiries" },
  { href: "/app/admin/users", label: "Users" },
  { href: "/app/admin/orgs", label: "Orgs" },
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
              const active = link.exact
                ? pathname === link.href
                : pathname === link.href || pathname.startsWith(link.href + "/");
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
          </ul>
        </nav>
      </aside>
      <main className="sg-admin-main">{children}</main>
    </div>
  );
}
