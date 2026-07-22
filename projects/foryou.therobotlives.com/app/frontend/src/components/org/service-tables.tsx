"use client";

// Presentational tables shared by the admin console and the org dashboard.
// Both surfaces read the same org-scoped endpoints; only the drill-down link
// targets differ, so callers pass an `hrefFor` builder.

import Link from "next/link";
import { optInMode, type OrgList } from "@/lib/org-api";
import { Badge, OptInBadge } from "@/components/admin/ui";

export interface ServiceRow {
  id: string;
  slug: string;
  name: string;
  list_count: number | null;
  signup_count: number | null;
}

export function ServicesTable({
  rows,
  hrefFor,
}: {
  rows: ServiceRow[];
  hrefFor: (service: ServiceRow) => string;
}) {
  return (
    <div className="sg-table--scroll">
      <table className="sg-table">
        <thead>
          <tr>
            <th>Service</th>
            <th>Slug</th>
            <th>Lists</th>
            <th>Signups</th>
          </tr>
        </thead>
        <tbody>
          {rows.map((s) => (
            <tr key={s.id}>
              <td>
                <Link href={hrefFor(s)} className="sg-admin-nav-link" style={{ padding: 0 }}>
                  {s.name}
                </Link>
              </td>
              <td className="sg-td-muted">{s.slug}</td>
              <td>{s.list_count ?? "—"}</td>
              <td>{s.signup_count ?? "—"}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

export function ListsTable({
  lists,
  hrefFor,
}: {
  lists: OrgList[];
  hrefFor: (list: OrgList) => string;
}) {
  return (
    <div className="sg-table--scroll">
      <table className="sg-table">
        <thead>
          <tr>
            <th>Name</th>
            <th>Slug</th>
            <th>Kind</th>
            <th>Opt-in</th>
            <th>Signups</th>
            <th>Status</th>
          </tr>
        </thead>
        <tbody>
          {lists.map((l) => (
            <tr key={l.id}>
              <td>
                <Link href={hrefFor(l)} className="sg-admin-nav-link" style={{ padding: 0 }}>
                  {l.name}
                </Link>
              </td>
              <td className="sg-td-muted">{l.slug}</td>
              <td>
                <Badge tone="neutral">{l.kind}</Badge>
              </td>
              <td>
                <OptInBadge mode={optInMode(l)} />
              </td>
              <td>{l.signup_count}</td>
              <td>
                {l.status === "archived" ? <Badge tone="muted">Archived</Badge> : <Badge tone="success">Active</Badge>}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
