"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { useOrg } from "@/context/org";
import { adminListServices, adminListLists, type AdminList } from "@/components/admin/admin-fetch";
import { EmptyState, ErrorPanel, StatGrid, StatTile, SkeletonTiles } from "@/components/admin/ui";

interface TopList extends AdminList {
  service_id: string;
  service_name: string;
}

interface Aggregate {
  services: number;
  lists: number;
  signups: number;
  topLists: TopList[];
}

export default function AdminDashboardPage() {
  const { currentOrg, loading: orgLoading } = useOrg();
  const [agg, setAgg] = useState<Aggregate | null>(null);
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
        let listCount = 0;
        let signupCount = 0;
        const topLists: TopList[] = [];
        await Promise.all(
          services.map(async (svc) => {
            try {
              const lr = await adminListLists(currentOrg.id, svc.id);
              listCount += lr.lists.length;
              for (const l of lr.lists) {
                signupCount += l.signup_count || 0;
                topLists.push({ ...l, service_id: svc.id, service_name: svc.name });
              }
            } catch {
              /* skip services we can't read */
            }
          })
        );
        topLists.sort((a, b) => (b.signup_count || 0) - (a.signup_count || 0));
        if (!cancelled) {
          setAgg({
            services: services.length,
            lists: listCount,
            signups: signupCount,
            topLists: topLists.slice(0, 5),
          });
        }
      })
      .catch((e) => {
        if (!cancelled) setError(e instanceof Error ? e.message : "Failed to load dashboard");
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
        <h1 className="sg-section-heading">Dashboard</h1>
        <SkeletonTiles count={3} />
      </div>
    );
  }
  if (!currentOrg) {
    return (
      <div>
        <h1 className="sg-section-heading">Dashboard</h1>
        <EmptyState
          title="No organization selected"
          message="Create or select an organization to see its signup activity."
          cta={{ href: "/app", label: "Go to app" }}
        />
      </div>
    );
  }
  if (error) {
    return (
      <div>
        <h1 className="sg-section-heading">Dashboard</h1>
        <ErrorPanel message={error} />
      </div>
    );
  }

  const a = agg!;
  return (
    <div>
      <h1 className="sg-section-heading">Dashboard</h1>
      <p className="sg-page-intro">Signup activity across {currentOrg.name}.</p>

      <StatGrid>
        <StatTile label="Services" value={a.services} />
        <StatTile label="Lists" value={a.lists} />
        <StatTile label="Signups" value={a.signups} />
      </StatGrid>

      <h2 className="sg-section-heading" style={{ fontSize: "1.125rem" }}>
        Top lists by signups
      </h2>
      {a.topLists.length === 0 ? (
        <EmptyState title="No signups yet" message="Signups will appear here once your lists start collecting them." cta={{ href: "/app/admin/services", label: "View services" }} />
      ) : (
        <div className="sg-table--scroll">
          <table className="sg-table">
            <thead>
              <tr>
                <th>List</th>
                <th>Service</th>
                <th>Signups</th>
              </tr>
            </thead>
            <tbody>
              {a.topLists.map((l) => (
                <tr key={l.id}>
                  <td>
                    <Link
                      href={`/app/admin/services/${l.service_id}/lists/${l.id}`}
                      className="sg-admin-nav-link"
                      style={{ padding: 0 }}
                    >
                      {l.name}
                    </Link>
                  </td>
                  <td className="sg-td-muted">{l.service_name}</td>
                  <td>{l.signup_count}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      <p className="sg-notice" style={{ marginTop: "1.5rem" }}>
        Signup-volume trends and rate-limit / abuse metrics will appear here once the observability
        endpoint is wired (backend fast-follow).
      </p>
    </div>
  );
}
