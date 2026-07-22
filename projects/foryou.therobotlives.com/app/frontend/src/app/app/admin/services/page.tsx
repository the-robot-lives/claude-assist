"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { useOrg } from "@/context/org";
import { adminListServices, adminListLists, type AdminService } from "@/components/admin/admin-fetch";
import { EmptyState, ErrorPanel, SkeletonRows } from "@/components/admin/ui";

interface ServiceRow extends AdminService {
  list_count: number | null;
  signup_count: number | null;
}

export default function ServicesPage() {
  const { currentOrg, loading: orgLoading } = useOrg();
  const [rows, setRows] = useState<ServiceRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (orgLoading) return;
    if (!currentOrg) {
      setLoading(false);
      return;
    }
    let cancelled = false;
    setLoading(true);
    setError(null);

    adminListServices(currentOrg.id)
      .then(async (res) => {
        const services = res.projects ?? res.organizations ?? [];
        // Aggregate list/signup counts per service (no backend counts endpoint).
        const withCounts = await Promise.all(
          services.map(async (svc): Promise<ServiceRow> => {
            try {
              const lr = await adminListLists(currentOrg.id, svc.id);
              const signups = lr.lists.reduce((sum, l) => sum + (l.signup_count || 0), 0);
              return { ...svc, list_count: lr.lists.length, signup_count: signups };
            } catch {
              return { ...svc, list_count: null, signup_count: null };
            }
          })
        );
        if (!cancelled) setRows(withCounts);
      })
      .catch((e) => {
        if (!cancelled) setError(e instanceof Error ? e.message : "Failed to load services");
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [currentOrg, orgLoading]);

  if (orgLoading || loading) {
    return (
      <div>
        <h1 className="sg-section-heading">Services</h1>
        <SkeletonRows count={5} />
      </div>
    );
  }
  if (!currentOrg) {
    return (
      <div>
        <h1 className="sg-section-heading">Services</h1>
        <EmptyState
          title="No organization selected"
          message="Create or select an organization to see its services."
          cta={{ href: "/app", label: "Go to app" }}
        />
      </div>
    );
  }
  if (error) {
    return (
      <div>
        <h1 className="sg-section-heading">Services</h1>
        <ErrorPanel message={error} />
      </div>
    );
  }

  return (
    <div>
      <h1 className="sg-section-heading">Services</h1>
      <p className="sg-page-intro">Signup lists across {currentOrg.name}. Drill into a service to see its lists and signups.</p>

      {rows.length === 0 ? (
        <EmptyState title="No services yet" message="This organization has no services (projects) yet." />
      ) : (
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
                    <Link href={`/app/admin/services/${s.id}`} className="sg-admin-nav-link" style={{ padding: 0 }}>
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
      )}
    </div>
  );
}
