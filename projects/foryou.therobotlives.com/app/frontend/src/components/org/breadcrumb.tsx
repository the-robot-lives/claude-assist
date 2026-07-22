"use client";

// Lightweight breadcrumb trail for the org dashboard drill-down
// (dashboard → site → list). Uses the admin console's `sg-*` styling tokens so
// the two surfaces stay visually consistent.

import "@/components/admin/admin.css";
import Link from "next/link";
import { Fragment } from "react";

export interface Crumb {
  href?: string;
  label: string;
}

export function Breadcrumb({ items }: { items: Crumb[] }) {
  return (
    <nav aria-label="Breadcrumb" className="sg-back-link" style={{ display: "flex", flexWrap: "wrap", gap: "0.35rem", alignItems: "center" }}>
      {items.map((c, i) => {
        const last = i === items.length - 1;
        return (
          <Fragment key={`${c.label}-${i}`}>
            {c.href && !last ? (
              <Link href={c.href} className="sg-back-link" style={{ margin: 0 }}>
                {c.label}
              </Link>
            ) : (
              <span aria-current={last ? "page" : undefined} className="sg-td-muted">
                {c.label}
              </span>
            )}
            {last ? null : <span aria-hidden="true" className="sg-td-muted">/</span>}
          </Fragment>
        );
      })}
    </nav>
  );
}
