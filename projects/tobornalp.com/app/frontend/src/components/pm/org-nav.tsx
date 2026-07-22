'use client';

import Link from "next/link";
import { usePathname } from "next/navigation";
import { useOrg } from "@/context/org";
import { ReactNode } from "react";

// Secondary, org-scoped navigation for the PM surfaces (Today/Items/Inbox/Goals).
// Rendered inside [orgId]/layout so links only appear within an org context.
// `usePathname` highlights the active section.
const SECTIONS = [
  { slug: "today", label: "Today" },
  { slug: "projects", label: "Projects" },
  { slug: "items", label: "Items" },
  { slug: "personal", label: "Personal" },
  { slug: "inbox", label: "Inbox" },
  { slug: "goals", label: "Goals" },
];

export function OrgNav({ children }: { children: ReactNode }) {
  const { currentOrg } = useOrg();
  const pathname = usePathname();

  // orgId may come from context or the URL segment; prefer context's resolved id.
  const orgId = currentOrg?.id;

  return (
    <div className="mx-auto flex min-h-screen max-w-6xl">
      {orgId && (
        <aside className="hidden w-44 shrink-0 border-r border-border px-2 py-6 md:block">
          <nav className="sticky top-6 space-y-1">
            {SECTIONS.map((s) => {
              const href = `/app/${orgId}/${s.slug}`;
              const active = pathname?.startsWith(href);
              return (
                <Link
                  key={s.slug}
                  href={href}
                  className={`block rounded px-2.5 py-1.5 text-sm ${
                    active ? "bg-surface-alt font-medium text-text" : "text-text-secondary hover:bg-surface-alt hover:text-text"
                  }`}
                >
                  {s.label}
                </Link>
              );
            })}
            {/* Switch between orgs or create a new one (owner of many). The
                ?create=1 intent flag stops the single-org auto-redirect on /app. */}
            <Link
              href="/app?create=1"
              className="mt-2 block rounded border-t border-border px-2.5 pt-3 text-sm text-text-secondary hover:text-text"
            >
              + New organization
            </Link>
          </nav>
        </aside>
      )}
      <main className="min-w-0 flex-1">{children}</main>
    </div>
  );
}
