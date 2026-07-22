"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { useParams } from "next/navigation";
import { useOrg } from "@/context/org";
import { listServices, listServiceLists, OrgApiError, type OrgList } from "@/lib/org-api";
import { EmptyState, ErrorPanel, SkeletonRows } from "@/components/admin/ui";
import { ListsTable } from "@/components/org/service-tables";

interface SiteWithLists {
  id: string;
  slug: string;
  name: string;
  lists: OrgList[];
  signup_count: number;
}

export default function OrgDashboard() {
  const { orgId } = useParams<{ orgId: string }>();
  const { organizations, currentOrg } = useOrg();

  const [sites, setSites] = useState<SiteWithLists[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [errorStatus, setErrorStatus] = useState<number | null>(null);

  // Org name from the URL-selected org (not necessarily the switcher's current).
  const orgName = organizations.find((o) => o.id === orgId)?.name ?? currentOrg?.name ?? "Organization";

  useEffect(() => {
    if (!orgId) return;
    let cancelled = false;
    setLoading(true);
    setError(null);
    setErrorStatus(null);

    listServices(orgId)
      .then(async (res) => {
        const services = res.projects ?? res.organizations ?? [];
        const withLists = await Promise.all(
          services.map(async (svc): Promise<SiteWithLists> => {
            try {
              const lr = await listServiceLists(orgId, svc.id);
              const signups = lr.lists.reduce((sum, l) => sum + (l.signup_count || 0), 0);
              return { id: svc.id, slug: svc.slug, name: svc.name, lists: lr.lists, signup_count: signups };
            } catch {
              return { id: svc.id, slug: svc.slug, name: svc.name, lists: [], signup_count: 0 };
            }
          })
        );
        if (!cancelled) setSites(withLists);
      })
      .catch((e) => {
        if (cancelled) return;
        setErrorStatus(e instanceof OrgApiError ? e.status : null);
        setError(e instanceof Error ? e.message : "Failed to load sites");
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });

    return () => {
      cancelled = true;
    };
  }, [orgId]);

  return (
    <div style={{ maxWidth: 960, margin: "2rem auto", padding: "0 1.25rem" }}>
      <h1 className="sg-section-heading">{orgName}</h1>
      <p className="sg-page-intro">
        Sites and their signup lists across this organization. Drill into a site to review its lists and signups.
      </p>

      {loading ? (
        <SkeletonRows count={5} />
      ) : error && errorStatus === 403 ? (
        <ErrorPanel message="Access denied — you do not have permission to view this organization's sites." />
      ) : error ? (
        <ErrorPanel message={error} />
      ) : sites.length === 0 ? (
        <EmptyState
          title="No sites yet"
          message="This organization has no sites yet. Sites are provisioned via terraform."
        />
      ) : (
        <div style={{ display: "flex", flexDirection: "column", gap: "2rem" }}>
          {sites.map((site) => (
            <section key={site.id}>
              <div className="sg-section-header">
                <div>
                  <h2 className="sg-section-heading" style={{ marginBottom: "0.25rem" }}>
                    <Link href={`/app/${orgId}/services/${site.id}`} className="sg-admin-nav-link" style={{ padding: 0 }}>
                      {site.name}
                    </Link>
                  </h2>
                  <p className="sg-td-muted" style={{ margin: 0, fontSize: "0.8125rem" }}>
                    {site.lists.length} list{site.lists.length === 1 ? "" : "s"} · {site.signup_count} signup
                    {site.signup_count === 1 ? "" : "s"}
                  </p>
                </div>
                <div className="sg-section-header__actions">
                  <Link href={`/app/${orgId}/services/${site.id}`} className="sg-btn sg-btn--outline sg-btn--sm">
                    View site
                  </Link>
                </div>
              </div>

              {site.lists.length === 0 ? (
                <EmptyState title="No lists yet" message="Lists for this site will appear here once created." />
              ) : (
                <ListsTable lists={site.lists} hrefFor={(l) => `/app/${orgId}/services/${site.id}/lists/${l.id}`} />
              )}
            </section>
          ))}
        </div>
      )}
    </div>
  );
}
